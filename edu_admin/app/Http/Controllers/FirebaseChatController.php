<?php

namespace App\Http\Controllers;

use Google\Client;
use App\Models\GlobalSettings;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

class FirebaseChatController extends Controller
{
    public function firebaseChats()
    {
        $chatUsers = Users::select('id', 'username', 'fullname', 'identity')
            ->orderBy('username')
            ->get()
            ->map(function ($user) {
                $name = trim((string) ($user->fullname ?? ''));
                if ($name === '') {
                    $name = trim((string) ($user->username ?? ''));
                }
                if ($name === '') {
                    $name = trim((string) ($user->identity ?? ''));
                }
                if ($name === '') {
                    $name = 'User ' . intval($user->id);
                }

                return $name . ' (' . intval($user->id) . ')';
            })
            ->unique()
            ->values();

        return view('firebaseChats', compact('chatUsers'));
    }

    public function listFirebaseChats(Request $request)
    {
        $rows = $this->fetchFirebaseChatRows();

        $totalData = count($rows);
        $filterDate = trim((string) $request->input('filter_date', ''));
        $filterSender = strtolower(trim((string) $request->input('sender', '')));
        $filterReceiver = strtolower(trim((string) $request->input('receiver', '')));

        if ($filterDate !== '') {
            $rows = array_values(array_filter($rows, function ($item) use ($filterDate) {
                $time = (string) ($item['time'] ?? '');
                return str_starts_with($time, $filterDate);
            }));
        }

        if ($filterSender !== '') {
            $rows = array_values(array_filter($rows, function ($item) use ($filterSender) {
                $senderHaystack = strtolower(
                    (string) ($item['sender_display'] ?? '') . ' ' . (string) ($item['sender_id'] ?? '')
                );
                return str_contains($senderHaystack, $filterSender);
            }));
        }

        if ($filterReceiver !== '') {
            $rows = array_values(array_filter($rows, function ($item) use ($filterReceiver) {
                $receiverHaystack = strtolower(
                    (string) ($item['receiver_display'] ?? '') . ' ' . (string) ($item['receiver_id'] ?? '')
                );
                return str_contains($receiverHaystack, $filterReceiver);
            }));
        }

        $searchValue = trim((string) $request->input('search.value', ''));
        if ($searchValue !== '') {
            $rows = array_values(array_filter($rows, function ($item) use ($searchValue) {
                $needle = strtolower($searchValue);
                $haystack = strtolower(
                    ($item['room_id'] ?? '') . ' ' .
                    ($item['sender_id'] ?? '') . ' ' .
                    ($item['receiver_id'] ?? '') . ' ' .
                    ($item['message'] ?? '') . ' ' .
                    ($item['message_id'] ?? '')
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
                e($item['room_id'] ?? '-'),
                e($item['message_id'] ?? '-'),
                e((string) ($item['sender_display'] ?? ($item['sender_id'] ?? '-'))),
                e((string) ($item['receiver_display'] ?? ($item['receiver_id'] ?? '-'))),
                e((string) ($item['message_type'] ?? '-')),
                e((string) ($item['message'] ?? '-')),
                e($item['time'] ?? '-'),
                "<code class='small'>{$rawJson}</code>",
            ];
        }, $slice);

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => $totalData,
            'recordsFiltered' => $totalFiltered,
            'data' => $data,
        ]);
    }

    private function fetchFirebaseChatRows(): array
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
            if ($accessToken === '') {
                return [];
            }

            $userMap = $this->fetchAppUsersMap($projectId, $accessToken);
            $rows = $this->fetchMessagesCollectionGroup($projectId, $accessToken, $userMap);

            usort($rows, static function ($a, $b) {
                return ($b['sort_time'] ?? 0) <=> ($a['sort_time'] ?? 0);
            });

            return $rows;
        } catch (\Throwable $e) {
            Log::error('Firestore chat fetch exception', ['error' => $e->getMessage()]);
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
            Log::warning('Firestore access token generation failed, using fallback token if available', [
                'error' => $e->getMessage(),
            ]);
        }

        return $this->getStoredGoogleAccessToken();
    }

    private function getStoredGoogleAccessToken(): string
    {
        try {
            $settings = GlobalSettings::first();
            return trim((string) ($settings->place_api_access_token ?? ''));
        } catch (\Throwable $e) {
            return '';
        }
    }

    private function fetchAppUsersMap(string $projectId, string $accessToken): array
    {
        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents/app_users?pageSize=1000";
        $response = Http::withToken($accessToken)->timeout(30)->get($url);
        if (!$response->successful()) {
            Log::warning('Failed to fetch app_users from Firestore', [
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

    private function fetchMessagesCollectionGroup(string $projectId, string $accessToken, array $userMap): array
    {
        $limit = intval(env('FIRESTORE_CHAT_LIMIT', 1000));
        if ($limit < 1) {
            $limit = 1000;
        }

        $url = "https://firestore.googleapis.com/v1/projects/{$projectId}/databases/(default)/documents:runQuery";
        $payload = [
            'structuredQuery' => [
                'from' => [
                    ['collectionId' => 'messages', 'allDescendants' => true],
                ],
                'limit' => $limit,
            ],
        ];

        $response = Http::withToken($accessToken)->timeout(30)->post($url, $payload);
        if (!$response->successful()) {
            Log::warning('Failed to fetch messages collection group', [
                'status' => $response->status(),
                'body' => $response->body(),
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
            $conversationId = (string) ($fields['conversation_id'] ?? $this->extractConversationIdFromMessageDocName((string) ($doc['name'] ?? '')));
            if ($conversationId === '') {
                continue;
            }

            $senderId = (string) ($fields['user_id'] ?? '');
            $receiverId = $this->resolveReceiverId($conversationId, $senderId);

            $messageType = (string) ($fields['message_type'] ?? 'text');
            $messageText = $this->resolveMessageText($fields, $messageType);
            $messageId = (string) ($fields['id'] ?? $this->extractLastPathSegment((string) ($doc['name'] ?? '')));
            $sortTime = $this->resolveSortTime($fields['id'] ?? $messageId ?? null);
            if ($sortTime <= 0 && !empty($doc['createTime'])) {
                $sortTime = $this->resolveSortTime($doc['createTime']);
            }

            $senderProfile = $userMap[$senderId] ?? [];
            $receiverProfile = $userMap[$receiverId] ?? [];

            $rows[] = [
                'room_id' => $conversationId,
                'message_id' => $messageId !== '' ? $messageId : '-',
                'sender_id' => $senderId !== '' ? $senderId : '-',
                'receiver_id' => $receiverId !== '' ? $receiverId : '-',
                'sender_display' => $this->buildUserDisplay($senderId, $senderProfile),
                'receiver_display' => $this->buildUserDisplay($receiverId, $receiverProfile),
                'message_type' => $messageType,
                'message' => $messageText,
                'time' => $sortTime > 0 ? Carbon::createFromTimestampMs($sortTime)->format('Y-m-d H:i:s') : '-',
                'sort_time' => $sortTime,
                'raw' => $fields,
            ];
        }

        return $rows;
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

    private function extractConversationIdFromMessageDocName(string $docName): string
    {
        if ($docName === '') {
            return '';
        }
        // projects/{p}/databases/(default)/documents/chats/{conversationId}/messages/{messageId}
        if (preg_match('#/documents/chats/([^/]+)/messages/[^/]+$#', $docName, $matches)) {
            return (string) ($matches[1] ?? '');
        }
        return '';
    }

    private function extractLastPathSegment(string $path): string
    {
        $parts = explode('/', trim($path, '/'));
        return !empty($parts) ? (string) end($parts) : '';
    }

    private function resolveReceiverId(string $conversationId, string $senderId): string
    {
        $parts = explode('_', $conversationId);
        if (count($parts) !== 2) {
            return '';
        }
        if ((string) $parts[0] === (string) $senderId) {
            return (string) $parts[1];
        }
        if ((string) $parts[1] === (string) $senderId) {
            return (string) $parts[0];
        }
        return '';
    }

    private function resolveMessageText(array $fields, string $messageType): string
    {
        $messageType = strtolower($messageType);
        if ($messageType === 'text') {
            return (string) ($fields['text_message'] ?? '');
        }
        if ($messageType === 'image') {
            return '[Image] ' . (string) ($fields['image_message'] ?? '');
        }
        if ($messageType === 'video') {
            return '[Video] ' . (string) ($fields['video_message'] ?? '');
        }
        if ($messageType === 'audio') {
            return '[Audio] ' . (string) ($fields['audio_message'] ?? '');
        }
        if ($messageType === 'gif') {
            return '[GIF] ' . (string) ($fields['gif_message'] ?? '');
        }
        if ($messageType === 'gift') {
            return '[Gift] ' . (string) ($fields['gift_message'] ?? ($fields['text_message'] ?? ''));
        }
        if ($messageType === 'post') {
            return '[Post] ' . (string) ($fields['post_message'] ?? ($fields['text_message'] ?? ''));
        }
        if ($messageType === 'story_reply') {
            return '[Story Reply] ' . (string) ($fields['text_message'] ?? '');
        }
        return (string) ($fields['text_message'] ?? '');
    }

    private function buildUserDisplay(string $userId, array $profile): string
    {
        $name = trim((string) ($profile['fullname'] ?? ''));
        if ($name === '') {
            $name = trim((string) ($profile['username'] ?? ''));
        }
        if ($name === '') {
            $name = trim((string) ($profile['identity'] ?? ''));
        }
        if ($name === '') {
            $name = $userId !== '' ? "User {$userId}" : '-';
        }
        return $name . ($userId !== '' ? " ({$userId})" : '');
    }

    private function resolveSortTime($rawTimestamp): int
    {
        if (is_numeric($rawTimestamp)) {
            $ts = (int) $rawTimestamp;
            if ($ts > 9999999999) {
                return $ts; // milliseconds
            }
            if ($ts > 0) {
                return $ts * 1000; // seconds to milliseconds
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
}
