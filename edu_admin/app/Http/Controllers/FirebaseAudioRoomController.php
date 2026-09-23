<?php

namespace App\Http\Controllers;

use App\Models\GlobalSettings;
use Google\Client;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseAudioRoomController extends Controller
{
    private array $debugMeta = [];
    private array $queryAttempts = [];

    public function firebaseAudioRooms()
    {
        return view('firebaseAudioRooms');
    }

    public function listFirebaseAudioRooms(Request $request)
    {
        $rows = $this->fetchFirebaseAudioRoomRows();
        $totalData = count($rows);

        $filterActive = trim((string) $request->input('filter_active', ''));
        $filterHost = trim((string) $request->input('filter_host_id', ''));

        if ($filterActive !== '' && in_array($filterActive, ['1', '0'], true)) {
            $rows = array_values(array_filter($rows, function ($item) use ($filterActive) {
                return intval($item['is_active'] ?? 0) === intval($filterActive);
            }));
        }

        if ($filterHost !== '') {
            $rows = array_values(array_filter($rows, function ($item) use ($filterHost) {
                $haystack = strtolower((string) ($item['host_id'] ?? '') . ' ' . (string) ($item['host_name'] ?? ''));
                return str_contains($haystack, strtolower($filterHost));
            }));
        }

        $searchValue = trim((string) $request->input('search.value', ''));
        if ($searchValue !== '') {
            $needle = strtolower($searchValue);
            $rows = array_values(array_filter($rows, function ($item) use ($needle) {
                $haystack = strtolower(
                    (string) ($item['room_id'] ?? '') . ' ' .
                    (string) ($item['host_id'] ?? '') . ' ' .
                    (string) ($item['host_name'] ?? '') . ' ' .
                    (string) ($item['room_name'] ?? '') . ' ' .
                    (string) ($item['language_name'] ?? '') . ' ' .
                    (string) ($item['hashtag'] ?? '')
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
                e((string) ($item['room_id'] ?? '-')),
                e((string) ($item['host_id'] ?? '-')),
                e((string) ($item['host_name'] ?? '-')),
                e((string) ($item['room_name'] ?? '-')),
                e((string) ($item['language_name'] ?? '-')),
                e((string) ($item['max_participants'] ?? '0')),
                e((string) ($item['participant_count'] ?? '0')),
                e((string) ($item['is_active_label'] ?? '-')),
                e((string) ($item['created_at'] ?? '-')),
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

    private function fetchFirebaseAudioRoomRows(): array
    {
        try {
            $projectId = trim((string) env('FIRESTORE_PROJECT_ID', ''));
            if ($projectId === '') {
                $credentialsPath = base_path('googleCredentials.json');
                if (is_file($credentialsPath)) {
                    $credentials = json_decode((string) file_get_contents($credentialsPath), true);
                    $projectId = trim((string) ($credentials['project_id'] ?? ''));
                }
            }
            if ($projectId === '') {
                Log::warning('Audio rooms listing failed: FIRESTORE_PROJECT_ID missing');
                return [];
            }

            $accessToken = $this->getFirestoreAccessToken();
            $webApiKey = trim((string) env('FIREBASE_WEB_API_KEY', ''));
            if ($accessToken === '' && $webApiKey === '') {
                Log::warning('Audio rooms listing failed: Firestore access token and FIREBASE_WEB_API_KEY both empty');
                return [];
            }

            $primaryCollection = trim((string) env('FIRESTORE_AUDIO_ROOM_COLLECTION', 'audio_rooms'));
            if ($primaryCollection === '') {
                $primaryCollection = 'audio_rooms';
            }
            $collections = array_values(array_unique(array_filter([
                $primaryCollection,
                'audio_rooms',
                'audioRooms',
                'audio_room',
                'audiorooms',
            ])));
            $discoveredCollections = $this->discoverFirestoreCollections($projectId, $accessToken, $webApiKey);
            $audioLikeCollections = array_values(array_filter($discoveredCollections, static function ($name) {
                $n = strtolower((string) $name);
                return str_contains($n, 'audio') || str_contains($n, 'room');
            }));
            if (!empty($audioLikeCollections)) {
                $collections = array_values(array_unique(array_merge($collections, $audioLikeCollections)));
            }
            $limit = intval(env('FIRESTORE_AUDIO_ROOM_LIMIT', 1000));
            if ($limit < 1) {
                $limit = 1000;
            }

            $documents = [];
            $matchedCollection = '';
            foreach ($collections as $collectionId) {
                $documents = $this->fetchAudioRoomDocuments($projectId, $collectionId, $limit, $accessToken, $webApiKey);
                if (empty($documents)) {
                    $documents = $this->fetchAudioRoomDocumentsByRunQuery($projectId, $collectionId, $limit, $accessToken, $webApiKey, false);
                }
                if (empty($documents)) {
                    $documents = $this->fetchAudioRoomDocumentsByRunQuery($projectId, $collectionId, $limit, $accessToken, $webApiKey, true);
                }
                if (!empty($documents)) {
                    $matchedCollection = $collectionId;
                    break;
                }
            }
            $this->debugMeta = [
                'project_id' => $projectId,
                'collection' => $matchedCollection !== '' ? $matchedCollection : $primaryCollection,
                'documents_count' => count($documents),
                'has_access_token' => $accessToken !== '',
                'has_web_api_key' => $webApiKey !== '',
                'discovered_collections' => $audioLikeCollections,
                'query_attempts' => $this->queryAttempts,
            ];
            if (empty($documents)) {
                return [];
            }

            $rows = [];
            foreach ($documents as $doc) {
                $fields = $this->decodeFirestoreFields($doc['fields'] ?? []);
                $participantIds = $fields['participant_ids'] ?? [];
                if (!is_array($participantIds)) {
                    $participantIds = [];
                }

                $createdAtMs = intval($fields['created_at'] ?? 0);
                $rows[] = [
                    'room_id' => (string) ($fields['room_id'] ?? $this->extractLastPathSegment((string) ($doc['name'] ?? '-'))),
                    'host_id' => intval($fields['host_id'] ?? $this->extractLastPathSegment((string) ($doc['name'] ?? '0'))),
                    'host_name' => (string) ($fields['host_name'] ?? '-'),
                    'host_photo' => (string) ($fields['host_photo'] ?? ''),
                    'room_name' => (string) ($fields['room_name'] ?? '-'),
                    'max_participants' => intval($fields['max_participants'] ?? 0),
                    'participant_ids' => $participantIds,
                    'participant_count' => count($participantIds),
                    'created_at_ms' => $createdAtMs,
                    'created_at' => $createdAtMs > 0 ? Carbon::createFromTimestampMs($createdAtMs)->format('Y-m-d H:i:s') : '-',
                    'is_active' => !empty($fields['is_active']) ? 1 : 0,
                    'is_active_label' => !empty($fields['is_active']) ? 'Live' : 'Ended',
                    'language_id' => intval($fields['language_id'] ?? 0),
                    'language_name' => (string) ($fields['language_name'] ?? '-'),
                    'is_auto_mode' => !empty($fields['is_auto_mode']) ? 1 : 0,
                    'chat_room_field' => (string) ($fields['chat_room_field'] ?? ''),
                    'hashtag' => (string) ($fields['hashtag'] ?? ''),
                    'music_url' => (string) ($fields['music_url'] ?? ''),
                    'background_image' => (string) ($fields['background_image'] ?? ''),
                    'raw' => $fields,
                ];
            }

            usort($rows, static function ($a, $b) {
                return intval($b['created_at_ms'] ?? 0) <=> intval($a['created_at_ms'] ?? 0);
            });

            return $rows;
        } catch (\Throwable $e) {
            Log::error('Firebase audio rooms fetch exception', [
                'error' => $e->getMessage(),
            ]);
            $this->debugMeta = [
                'error' => $e->getMessage(),
            ];
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
            Log::warning('Firestore token generation failed for audio rooms, using fallback', [
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

    private function fetchAudioRoomDocuments(string $projectId, string $collectionId, int $limit, string $accessToken, string $webApiKey): array
    {
        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/{$collectionId}?pageSize={$limit}";
        $response = $this->firestoreGet($url, $accessToken, $webApiKey);
        if (!$response) {
            $this->queryAttempts[] = [
                'method' => 'documents',
                'collection' => $collectionId,
                'status' => 'no_response',
            ];
            return [];
        }
        if (!$response->successful()) {
            $this->queryAttempts[] = [
                'method' => 'documents',
                'collection' => $collectionId,
                'status' => $response->status(),
            ];
            Log::warning('Failed to fetch audio room documents', [
                'status' => $response->status(),
                'body' => $response->body(),
                'collection' => $collectionId,
            ]);
            return [];
        }

        $documents = $response->json('documents') ?? [];
        $this->queryAttempts[] = [
            'method' => 'documents',
            'collection' => $collectionId,
            'status' => $response->status(),
            'count' => is_array($documents) ? count($documents) : 0,
        ];
        return is_array($documents) ? $documents : [];
    }

    private function fetchAudioRoomDocumentsByRunQuery(string $projectId, string $collectionId, int $limit, string $accessToken, string $webApiKey, bool $allDescendants = false): array
    {
        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents:runQuery";
        $payload = [
            'structuredQuery' => [
                'from' => [
                    ['collectionId' => $collectionId, 'allDescendants' => $allDescendants],
                ],
                'limit' => $limit,
            ],
        ];

        $response = $this->firestorePost($url, $payload, $accessToken, $webApiKey);
        if (!$response) {
            $this->queryAttempts[] = [
                'method' => 'runQuery',
                'collection' => $collectionId,
                'all_descendants' => $allDescendants ? 1 : 0,
                'status' => 'no_response',
            ];
            return [];
        }
        if (!$response->successful()) {
            $this->queryAttempts[] = [
                'method' => 'runQuery',
                'collection' => $collectionId,
                'all_descendants' => $allDescendants ? 1 : 0,
                'status' => $response->status(),
            ];
            Log::warning('Failed to fetch audio room runQuery rows', [
                'status' => $response->status(),
                'body' => $response->body(),
                'collection' => $collectionId,
                'all_descendants' => $allDescendants ? 1 : 0,
            ]);
            return [];
        }

        $entries = $response->json();
        if (!is_array($entries)) {
            return [];
        }

        $documents = [];
        foreach ($entries as $entry) {
            $doc = $entry['document'] ?? null;
            if (is_array($doc)) {
                $documents[] = $doc;
            }
        }
        $this->queryAttempts[] = [
            'method' => 'runQuery',
            'collection' => $collectionId,
            'all_descendants' => $allDescendants ? 1 : 0,
            'status' => $response->status(),
            'count' => count($documents),
        ];

        return $documents;
    }

    private function discoverFirestoreCollections(string $projectId, string $accessToken, string $webApiKey): array
    {
        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents:listCollectionIds";
        $payload = [
            'pageSize' => 200,
        ];
        $response = $this->firestorePost($url, $payload, $accessToken, $webApiKey);
        if (!$response || !$response->successful()) {
            return [];
        }

        $ids = $response->json('collectionIds') ?? [];
        if (!is_array($ids)) {
            return [];
        }

        return array_values(array_filter(array_map('strval', $ids)));
    }

    private function firestoreGet(string $url, string $accessToken, string $webApiKey = '')
    {
        try {
            if ($accessToken !== '') {
                return Http::withToken($accessToken)->timeout(30)->get($url);
            }
            if ($webApiKey !== '') {
                $separator = str_contains($url, '?') ? '&' : '?';
                return Http::timeout(30)->get($url . $separator . 'key=' . urlencode($webApiKey));
            }
        } catch (\Throwable $e) {
            Log::warning('Firestore GET failed for audio rooms', [
                'url' => $url,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
        return null;
    }

    private function firestorePost(string $url, array $payload, string $accessToken, string $webApiKey = '')
    {
        try {
            if ($accessToken !== '') {
                return Http::withToken($accessToken)->timeout(30)->post($url, $payload);
            }
            if ($webApiKey !== '') {
                $separator = str_contains($url, '?') ? '&' : '?';
                return Http::timeout(30)->post($url . $separator . 'key=' . urlencode($webApiKey), $payload);
            }
        } catch (\Throwable $e) {
            Log::warning('Firestore POST failed for audio rooms', [
                'url' => $url,
                'error' => $e->getMessage(),
            ]);
            return null;
        }
        return null;
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

        if (array_key_exists('nullValue', $value)) {
            return null;
        }
        if (array_key_exists('stringValue', $value)) {
            return (string) $value['stringValue'];
        }
        if (array_key_exists('integerValue', $value)) {
            return intval($value['integerValue']);
        }
        if (array_key_exists('doubleValue', $value)) {
            return floatval($value['doubleValue']);
        }
        if (array_key_exists('booleanValue', $value)) {
            return (bool) $value['booleanValue'];
        }
        if (array_key_exists('timestampValue', $value)) {
            return (string) $value['timestampValue'];
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
        $parts = explode('/', trim($path));
        return (string) end($parts);
    }
}
