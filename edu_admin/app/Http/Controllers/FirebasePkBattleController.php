<?php

namespace App\Http\Controllers;

use App\Models\GlobalSettings;
use Google\Client;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebasePkBattleController extends Controller
{
    private array $debugMeta = [];
    private array $queryAttempts = [];

    public function firebasePkBattles()
    {
        return view('firebasePkBattles');
    }

    public function listFirebasePkBattles(Request $request)
    {
        $rows = $this->fetchFirebasePkBattleRows();

        $totalData = count($rows);
        $searchValue = trim((string) $request->input('search.value', ''));
        if ($searchValue !== '') {
            $rows = array_values(array_filter($rows, function ($item) use ($searchValue) {
                $needle = strtolower($searchValue);
                $haystack = strtolower(
                    ($item['battle_id'] ?? '') . ' ' .
                    ($item['host_id'] ?? '') . ' ' .
                    ($item['opponent_id'] ?? '') . ' ' .
                    ($item['winner_id'] ?? '') . ' ' .
                    ($item['status'] ?? '') . ' ' .
                    ($item['room_id'] ?? '')
                );
                return str_contains($haystack, $needle);
            }));
        }

        $totalFiltered = count($rows);
        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $slice = array_slice($rows, $start, $limit);

        $data = array_map(function ($item) {
            $rawJson = e(json_encode($item['raw'] ?? [], JSON_UNESCAPED_UNICODE));
            return [
                e((string) ($item['battle_id'] ?? '-')),
                e((string) ($item['room_id'] ?? '-')),
                e((string) ($item['category'] ?? '-')),
                e((string) ($item['language_id'] ?? '-')),
                e((string) ($item['battle_type'] ?? '-')),
                e((string) ($item['watching_count'] ?? '0')),
                e((string) ($item['like_count'] ?? '0')),
                e((string) ($item['host_display'] ?? ($item['host_id'] ?? '-'))),
                e((string) ($item['host_coin'] ?? '0')),
                e((string) ($item['opponent_display'] ?? ($item['opponent_id'] ?? '-'))),
                e((string) ($item['co_host_coin'] ?? '0')),
                e((string) ($item['winner_display'] ?? ($item['winner_id'] ?? '-'))),
                e((string) ($item['status'] ?? '-')),
                e((string) ($item['start_time'] ?? '-')),
                e((string) ($item['end_time'] ?? '-')),
                "<code class='small'>{$rawJson}</code>",
            ];
        }, $slice);

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => $totalData,
            'recordsFiltered' => $totalFiltered,
            'data' => $data,
            'meta' => app()->environment('local') ? $this->debugMeta : null,
        ]);
    }

    private function fetchFirebasePkBattleRows(): array
    {
        $projectId = trim((string) env('FIRESTORE_PROJECT_ID', ''));
        if ($projectId === '') {
            $credentialsPath = base_path('googleCredentials.json');
            if (is_file($credentialsPath)) {
                $credentials = json_decode((string) file_get_contents($credentialsPath), true);
                $projectId = trim((string) ($credentials['project_id'] ?? ''));
            }
        }
        if ($projectId === '') {
            return [];
        }

        try {
            $accessToken = $this->getFirestoreAccessToken();
            $webApiKey = trim((string) env('FIREBASE_WEB_API_KEY', ''));
            if ($accessToken === '' && $webApiKey === '') {
                Log::warning('PK battle listing failed: Firestore access token and FIREBASE_WEB_API_KEY both empty');
                return [];
            }

            $userMap = $this->fetchAppUsersMap($projectId, $accessToken, $webApiKey);
            $rows = $this->fetchPkBattleCollectionGroup($projectId, $accessToken, $webApiKey, $userMap);

            usort($rows, static function ($a, $b) {
                return ($b['sort_time'] ?? 0) <=> ($a['sort_time'] ?? 0);
            });

            return $rows;
        } catch (\Throwable $e) {
            Log::error('Firestore pk battle fetch exception', ['error' => $e->getMessage()]);
            return [];
        }
    }

    private function getFirestoreAccessToken(): string
    {
        $credentialsPath = base_path('googleCredentials.json');
        if (!is_file($credentialsPath)) {
            return $this->getStoredGoogleAccessToken();
        }

        try {
            $client = new Client();
            $client->setAuthConfig($credentialsPath);
            $client->addScope('https://www.googleapis.com/auth/datastore');
            $client->addScope('https://www.googleapis.com/auth/cloud-platform');
            $token = $client->fetchAccessTokenWithAssertion();
            if (is_array($token) && !empty($token['access_token'])) {
                return (string) $token['access_token'];
            }
        } catch (\Throwable $e) {
            Log::warning('Firestore token generation failed for PK battles, using fallback', [
                'error' => $e->getMessage(),
            ]);
        }

        return $this->getStoredGoogleAccessToken();
    }

    private function getStoredGoogleAccessToken(): string
    {
        $envToken = trim((string) env('FIRESTORE_ACCESS_TOKEN', ''));
        if ($envToken !== '') {
            return $envToken;
        }

        try {
            $settings = GlobalSettings::first();
            return trim((string) ($settings->place_api_access_token ?? ''));
        } catch (\Throwable $e) {
            return '';
        }
    }

    private function fetchAppUsersMap(string $projectId, string $accessToken, string $webApiKey = ''): array
    {
        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/app_users?pageSize=1000";
        $response = $this->firestoreGet($url, $accessToken, $webApiKey);
        if (!$response) {
            return [];
        }
        if (!$response->successful()) {
            Log::warning('Failed to fetch app_users for PK battles', [
                'status' => $response->status(),
                'body' => $response->body(),
            ]);
            return [];
        }

        $documents = $response->json('documents') ?? [];
        if (!is_array($documents)) {
            return [];
        }

        $map = [];
        foreach ($documents as $doc) {
            $fields = $this->decodeFirestoreFields($doc['fields'] ?? []);
            $uid = (string) ($fields['user_id'] ?? $this->extractLastPathSegment((string) ($doc['name'] ?? '')));
            if ($uid === '') {
                continue;
            }
            $map[$uid] = [
                'username' => $fields['username'] ?? null,
                'fullname' => $fields['fullname'] ?? null,
                'identity' => $fields['identity'] ?? null,
            ];
        }

        return $map;
    }

    private function fetchPkBattleCollectionGroup(string $projectId, string $accessToken, string $webApiKey, array $userMap): array
    {
        $primaryCollection = trim((string) env('FIRESTORE_PK_BATTLE_COLLECTION', 'livestreams'));
        if ($primaryCollection === '') {
            $primaryCollection = 'livestreams';
        }
        $collections = array_values(array_unique(array_filter([
            $primaryCollection,
            'livestreams',
            'live_streams',
            'liveStreams',
        ])));
        $limit = intval(env('FIRESTORE_PK_BATTLE_LIMIT', 1000));
        if ($limit < 1) {
            $limit = 1000;
        }

        foreach ($collections as $collectionId) {
            $rows = $this->queryPkBattleRows($projectId, $accessToken, $webApiKey, $collectionId, $limit, true, false, $userMap);
            if (!empty($rows)) {
                $this->debugMeta = [
                    'collection' => $collectionId,
                    'records' => count($rows),
                    'query_attempts' => $this->queryAttempts,
                ];
                return $rows;
            }

            // Fallback: fetch without strict type filter and map using battle markers.
            $rows = $this->queryPkBattleRows($projectId, $accessToken, $webApiKey, $collectionId, $limit, false, false, $userMap);
            if (!empty($rows)) {
                $this->debugMeta = [
                    'collection' => $collectionId,
                    'records' => count($rows),
                    'query_attempts' => $this->queryAttempts,
                ];
                return $rows;
            }

            // Fallback: collection group query in case collection is nested.
            $rows = $this->queryPkBattleRows($projectId, $accessToken, $webApiKey, $collectionId, $limit, false, true, $userMap);
            if (!empty($rows)) {
                $this->debugMeta = [
                    'collection' => $collectionId,
                    'records' => count($rows),
                    'query_attempts' => $this->queryAttempts,
                ];
                return $rows;
            }
        }

        $this->debugMeta = [
            'collection' => $primaryCollection,
            'records' => 0,
            'query_attempts' => $this->queryAttempts,
        ];
        return [];
    }

    private function queryPkBattleRows(
        string $projectId,
        string $accessToken,
        string $webApiKey,
        string $collectionId,
        int $limit,
        bool $filterBattleType,
        bool $allDescendants,
        array $userMap
    ): array {
        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents:runQuery";
        $structuredQuery = [
            'from' => [
                ['collectionId' => $collectionId, 'allDescendants' => $allDescendants],
            ],
            'limit' => $limit,
        ];
        if ($filterBattleType) {
            $structuredQuery['where'] = [
                'fieldFilter' => [
                    'field' => ['fieldPath' => 'type'],
                    'op' => 'EQUAL',
                    'value' => ['stringValue' => 'BATTLE'],
                ],
            ];
        }
        $payload = [
            'structuredQuery' => [
                ...$structuredQuery,
            ],
        ];
        $response = $this->firestorePost($url, $payload, $accessToken, $webApiKey);
        if (!$response) {
            $this->queryAttempts[] = [
                'collection' => $collectionId,
                'strict_filter' => $filterBattleType ? 1 : 0,
                'all_descendants' => $allDescendants ? 1 : 0,
                'status' => 'no_response',
            ];
            return [];
        }
        if (!$response->successful()) {
            $this->queryAttempts[] = [
                'collection' => $collectionId,
                'strict_filter' => $filterBattleType ? 1 : 0,
                'all_descendants' => $allDescendants ? 1 : 0,
                'status' => $response->status(),
            ];
            Log::warning('Failed to fetch pk battles collection', [
                'status' => $response->status(),
                'body' => $response->body(),
                'collection' => $collectionId,
                'strict_filter' => $filterBattleType ? 1 : 0,
                'all_descendants' => $allDescendants ? 1 : 0,
            ]);
            return [];
        }

        $rows = [];
        $entries = $response->json();
        if (!is_array($entries)) {
            return [];
        }

        foreach ($entries as $entry) {
            $doc = $entry['document'] ?? null;
            if (!is_array($doc)) {
                continue;
            }
            $fields = $this->decodeFirestoreFields($doc['fields'] ?? []);
            if (!$this->isPkBattleDocument($fields)) {
                continue;
            }

            $streamDocId = $this->extractLastPathSegment((string) ($doc['name'] ?? ''));
            $battleId = (string) ($fields['battle_id'] ?? $fields['id'] ?? $streamDocId);
            $roomId = (string) ($fields['room_id'] ?? $fields['live_stream_id'] ?? $fields['conversation_id'] ?? '-');
            $hostId = (string) ($fields['host_id'] ?? $fields['user_id_1'] ?? $fields['creator_id'] ?? $fields['from_user_id'] ?? '');
            $coHostIds = $this->normalizeIdsArray($fields['co_host_ids'] ?? ($fields['co-host_ids'] ?? []));
            $opponentId = (string) ($fields['opponent_id'] ?? ($coHostIds[0] ?? ($fields['user_id_2'] ?? $fields['challenger_id'] ?? $fields['to_user_id'] ?? '')));
            $status = (string) ($fields['battle_type'] ?? $fields['battle_status'] ?? $fields['status'] ?? '-');

            $startRaw = $fields['battle_created_at'] ?? $fields['start_time'] ?? $fields['started_at'] ?? $fields['startAt'] ?? null;
            $endRaw = $fields['end_time'] ?? $fields['ended_at'] ?? $fields['endAt'] ?? null;
            $createdRaw = $fields['created_at'] ?? null;
            $sortTime = $this->resolveSortTime($endRaw);
            if ($sortTime <= 0) {
                $sortTime = $this->resolveSortTime($startRaw);
            }
            if ($sortTime <= 0) {
                $sortTime = $this->resolveSortTime($createdRaw);
            }
            if ($sortTime <= 0) {
                $sortTime = $this->resolveSortTime($fields['id'] ?? $battleId);
            }

            $subCollectionDocId = $streamDocId !== '' ? $streamDocId : $hostId;
            $userStateStats = $this->fetchBattleUserStateStats($projectId, $accessToken, $webApiKey, $collectionId, $subCollectionDocId);
            $hostCoin = intval($userStateStats['host_coin'] ?? 0);
            $coHostCoin = intval($userStateStats['co_host_coin'] ?? 0);
            $winnerId = (string) ($userStateStats['winner_id'] ?? '');

            $opponentDisplay = $this->buildUsersDisplay($coHostIds, $userMap);
            if ($opponentDisplay === '-' && $opponentId !== '') {
                $opponentDisplay = $this->buildUserDisplay($opponentId, $userMap[$opponentId] ?? []);
            }

            $rows[] = [
                'battle_id' => $battleId !== '' ? $battleId : '-',
                'room_id' => $roomId !== '' ? $roomId : '-',
                'host_id' => $hostId !== '' ? $hostId : '-',
                'opponent_id' => $opponentId !== '' ? $opponentId : '-',
                'winner_id' => $winnerId !== '' ? $winnerId : '-',
                'host_display' => $this->buildUserDisplay($hostId, $userMap[$hostId] ?? []),
                'opponent_display' => $opponentDisplay,
                'winner_display' => $this->buildUserDisplay($winnerId, $userMap[$winnerId] ?? []),
                'status' => $status,
                'battle_type' => (string) ($fields['battle_type'] ?? '-'),
                'watching_count' => intval($fields['watching_count'] ?? 0),
                'like_count' => intval($fields['like_count'] ?? 0),
                'category' => (string) ($fields['category_name'] ?? ('#' . ($fields['category_id'] ?? '-'))),
                'language_id' => (string) ($fields['language_id'] ?? '-'),
                'host_coin' => $hostCoin,
                'co_host_coin' => $coHostCoin,
                'start_time' => $this->formatFirestoreTime($startRaw),
                'end_time' => $this->formatFirestoreTime($endRaw),
                'sort_time' => $sortTime,
                'raw' => $fields,
            ];
        }
        $this->queryAttempts[] = [
            'collection' => $collectionId,
            'strict_filter' => $filterBattleType ? 1 : 0,
            'all_descendants' => $allDescendants ? 1 : 0,
            'status' => $response->status(),
            'count' => count($rows),
        ];

        return $rows;
    }

    private function fetchBattleUserStateStats(string $projectId, string $accessToken, string $webApiKey, string $collectionId, string $roomId): array
    {
        if ($roomId === '' || $roomId === '-') {
            return [
                'host_coin' => 0,
                'co_host_coin' => 0,
                'winner_id' => '',
            ];
        }

        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/{$collectionId}/{$roomId}/user_state?pageSize=200";
        $response = $this->firestoreGet($url, $accessToken, $webApiKey, 20);
        if (!$response) {
            return [
                'host_coin' => 0,
                'co_host_coin' => 0,
                'winner_id' => '',
            ];
        }
        if (!$response->successful()) {
            return [
                'host_coin' => 0,
                'co_host_coin' => 0,
                'winner_id' => '',
            ];
        }

        $docs = $response->json('documents') ?? [];
        if (!is_array($docs)) {
            return [
                'host_coin' => 0,
                'co_host_coin' => 0,
                'winner_id' => '',
            ];
        }

        $hostCoin = 0;
        $hostId = '';
        $maxCoHostCoin = 0;
        $maxCoHostId = '';

        foreach ($docs as $doc) {
            $fields = $this->decodeFirestoreFields($doc['fields'] ?? []);
            $type = strtoupper((string) ($fields['type'] ?? ''));
            $coin = intval($fields['current_battle_coin'] ?? 0);
            $userId = (string) ($fields['user_id'] ?? '');

            if ($type === 'HOST') {
                if ($coin >= $hostCoin) {
                    $hostCoin = $coin;
                    $hostId = $userId;
                }
            } elseif ($type === 'CO-HOST' || $type === 'CO_HOST' || $type === 'COHOST') {
                if ($coin >= $maxCoHostCoin) {
                    $maxCoHostCoin = $coin;
                    $maxCoHostId = $userId;
                }
            }
        }

        $winnerId = '';
        if ($hostCoin > $maxCoHostCoin) {
            $winnerId = $hostId;
        } elseif ($maxCoHostCoin > $hostCoin) {
            $winnerId = $maxCoHostId;
        }

        return [
            'host_coin' => $hostCoin,
            'co_host_coin' => $maxCoHostCoin,
            'winner_id' => $winnerId,
        ];
    }

    private function isPkBattleDocument(array $fields): bool
    {
        $type = strtoupper(trim((string) ($fields['type'] ?? '')));
        if ($type === '') {
            $type = strtoupper(trim((string) ($fields['live_type'] ?? '')));
        }
        if ($type === '') {
            $type = strtoupper(trim((string) ($fields['stream_type'] ?? '')));
        }
        if ($type === '') {
            $type = strtoupper(trim((string) ($fields['pk_type'] ?? '')));
        }
        if (str_contains($type, 'BATTLE')) {
            return true;
        }

        // Fallback: include real (non-dummy) livestream rows with PK battle status.
        $battleType = strtoupper(trim((string) ($fields['battle_type'] ?? $fields['battle_status'] ?? '')));
        if (!in_array($battleType, ['INITIATE', 'WAITING', 'RUNNING', 'END', 'ENDED'], true)) {
            return false;
        }

        $isDummyLive = intval($fields['is_dummy_live'] ?? 0);
        return $isDummyLive !== 1;
    }

    private function decodeFirestoreFields(array $fields): array
    {
        $output = [];
        foreach ($fields as $key => $value) {
            $output[$key] = $this->decodeFirestoreValue($value);
        }
        return $output;
    }

    private function decodeFirestoreValue($value)
    {
        if (!is_array($value)) {
            return $value;
        }

        if (array_key_exists('stringValue', $value)) {
            return (string) $value['stringValue'];
        }
        if (array_key_exists('integerValue', $value)) {
            return (string) $value['integerValue'];
        }
        if (array_key_exists('doubleValue', $value)) {
            return floatval($value['doubleValue']);
        }
        if (array_key_exists('booleanValue', $value)) {
            return boolval($value['booleanValue']);
        }
        if (array_key_exists('timestampValue', $value)) {
            return (string) $value['timestampValue'];
        }
        if (array_key_exists('nullValue', $value)) {
            return null;
        }
        if (array_key_exists('arrayValue', $value)) {
            $arr = $value['arrayValue']['values'] ?? [];
            if (!is_array($arr)) {
                return [];
            }
            return array_map(fn($v) => $this->decodeFirestoreValue($v), $arr);
        }
        if (array_key_exists('mapValue', $value)) {
            return $this->decodeFirestoreFields($value['mapValue']['fields'] ?? []);
        }

        return $value;
    }

    private function extractLastPathSegment(string $path): string
    {
        $parts = explode('/', trim($path, '/'));
        return !empty($parts) ? (string) end($parts) : '';
    }

    private function buildUserDisplay(string $userId, array $profile): string
    {
        if ($userId === '') {
            return '-';
        }
        $name = trim((string) ($profile['fullname'] ?? ''));
        if ($name === '') {
            $name = trim((string) ($profile['username'] ?? ''));
        }
        if ($name === '') {
            $name = trim((string) ($profile['identity'] ?? ''));
        }
        if ($name === '') {
            $name = "User {$userId}";
        }
        return "{$name} ({$userId})";
    }

    private function buildUsersDisplay(array $ids, array $userMap): string
    {
        if (empty($ids)) {
            return '-';
        }
        $labels = [];
        foreach ($ids as $id) {
            $sid = (string) $id;
            if ($sid === '') {
                continue;
            }
            $labels[] = $this->buildUserDisplay($sid, $userMap[$sid] ?? []);
        }
        return empty($labels) ? '-' : implode(', ', $labels);
    }

    private function normalizeIdsArray($value): array
    {
        if (!is_array($value)) {
            return [];
        }
        $ids = [];
        foreach ($value as $item) {
            $sid = trim((string) $item);
            if ($sid !== '') {
                $ids[] = $sid;
            }
        }
        return array_values(array_unique($ids));
    }

    private function formatFirestoreTime($value): string
    {
        $sortTime = $this->resolveSortTime($value);
        if ($sortTime <= 0) {
            return '-';
        }
        return Carbon::createFromTimestampMs($sortTime)->format('Y-m-d H:i:s');
    }

    private function resolveSortTime($rawTimestamp): int
    {
        if (is_numeric($rawTimestamp)) {
            $ts = (int) $rawTimestamp;
            if ($ts > 9999999999) {
                return $ts; // ms
            }
            if ($ts > 0) {
                return $ts * 1000; // sec to ms
            }
        }

        if (is_string($rawTimestamp) && trim($rawTimestamp) !== '') {
            try {
                return Carbon::parse($rawTimestamp)->getTimestampMs();
            } catch (\Throwable $e) {
                return 0;
            }
        }

        return 0;
    }

    private function firestoreGet(string $url, string $accessToken, string $webApiKey = '', int $timeout = 30)
    {
        if ($accessToken !== '') {
            return Http::withToken($accessToken)->timeout($timeout)->get($url);
        }
        if ($webApiKey !== '') {
            return Http::timeout($timeout)->get($url, ['key' => $webApiKey]);
        }
        return null;
    }

    private function firestorePost(string $url, array $payload, string $accessToken, string $webApiKey = '', int $timeout = 30)
    {
        if ($accessToken !== '') {
            return Http::withToken($accessToken)->timeout($timeout)->post($url, $payload);
        }
        if ($webApiKey !== '') {
            $joiner = str_contains($url, '?') ? '&' : '?';
            return Http::timeout($timeout)->post($url . $joiner . 'key=' . urlencode($webApiKey), $payload);
        }
        return null;
    }
}
