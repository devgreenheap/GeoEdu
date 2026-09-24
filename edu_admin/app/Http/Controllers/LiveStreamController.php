<?php

namespace App\Http\Controllers;

use App\Models\DummyLiveVideos;
use App\Models\Categories;
use App\Models\Constants;
use App\Models\Followers;
use App\Models\Gifts;
use App\Models\Language;
use App\Models\LiveStreamComments;
use App\Models\LiveStreams;
use App\Models\Posts;
use App\Models\SubCategories;
use App\Models\Topics;
use App\Models\GlobalFunction;
use App\Models\GlobalSettings;
use App\Models\Users;
use Illuminate\Support\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;

class LiveStreamController extends Controller
{
    public function liveDetails()
    {
        return view('liveDetails');
    }

    private function hasDummyLiveLearningColumns(): bool
    {
        return Schema::hasTable('dummy_live_videos')
            && Schema::hasColumn('dummy_live_videos', 'category_id')
            && Schema::hasColumn('dummy_live_videos', 'sub_category_id')
            && Schema::hasColumn('dummy_live_videos', 'topic_id')
            && Schema::hasColumn('dummy_live_videos', 'language_id');
    }

    //
    public function saveLiveStreamComment(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'live_stream_id' => 'required|string|max:255',
            'sender_id' => 'required|exists:tbl_users,id',
            'receiver_id' => 'nullable|exists:tbl_users,id',
            'comment' => 'nullable|string',
            'comment_type' => 'required|in:TEXT,GIFT,JOINED,JOINED_CO_HOST,REQUEST',
            'gift_id' => 'nullable|exists:tbl_gifts,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        if (intval($request->sender_id) !== intval($user->id)) {
            return GlobalFunction::sendSimpleResponse(false, 'sender_id mismatch');
        }

        $commentType = strtoupper(trim($request->comment_type));
        if ($commentType === 'TEXT' && empty(trim((string) $request->comment))) {
            return GlobalFunction::sendSimpleResponse(false, 'comment is required for TEXT type');
        }

        if ($commentType === 'GIFT') {
            if (!$request->filled('gift_id')) {
                return GlobalFunction::sendSimpleResponse(false, 'gift_id is required for GIFT type');
            }
            if (!$request->filled('receiver_id')) {
                return GlobalFunction::sendSimpleResponse(false, 'receiver_id is required for GIFT type');
            }
            $gift = Gifts::find($request->gift_id);
            if (!$gift) {
                return GlobalFunction::sendSimpleResponse(false, 'Invalid gift');
            }
        }

        // The mobile client actually sends the Firestore room id, which for
        // real (non-dummy) streams is just the host's user_id as a string —
        // never the tbl_live_streams primary key. Checking `id` first was
        // wrong: once any stream ever existed whose PK happened to equal a
        // host's user_id, every future comment from that host got silently
        // filed under that old, unrelated stream forever (viewer/gift/join
        // counts permanently stuck at 0 on the real session). Resolve by the
        // host's currently-active (status=1) stream first; only fall back to
        // treating the value as a literal PK for the rare edge case where a
        // GIFT/JOIN lands just after the stream flipped to ended.
        $normalizedLiveStreamId = trim((string) $request->live_stream_id);
        $resolvedStream = null;

        if (is_numeric($normalizedLiveStreamId)) {
            $resolvedStream = LiveStreams::where('user_id', intval($normalizedLiveStreamId))
                ->where('status', 1)
                ->orderBy('id', 'DESC')
                ->first();
        }

        if (!$resolvedStream && is_numeric($request->receiver_id)) {
            // For gifts, receiver is usually the host.
            $resolvedStream = LiveStreams::where('user_id', intval($request->receiver_id))
                ->where('status', 1)
                ->orderBy('id', 'DESC')
                ->first();
        }

        if (!$resolvedStream && is_numeric($request->sender_id)) {
            // Sender may be host for own stream comments.
            $resolvedStream = LiveStreams::where('user_id', intval($request->sender_id))
                ->where('status', 1)
                ->orderBy('id', 'DESC')
                ->first();
        }

        if (!$resolvedStream) {
            // No active stream matched — fall back to the most recent
            // stream for that host/sender/receiver regardless of status
            // (covers a comment arriving just after the stream ended), and
            // only as an absolute last resort treat the value as a literal
            // primary key.
            foreach ([$normalizedLiveStreamId, $request->receiver_id, $request->sender_id] as $candidate) {
                if (!is_numeric($candidate)) {
                    continue;
                }
                $resolvedStream = LiveStreams::where('user_id', intval($candidate))
                    ->orderBy('id', 'DESC')
                    ->first();
                if ($resolvedStream) {
                    break;
                }
            }
        }

        if (!$resolvedStream) {
            $resolvedStream = LiveStreams::where('id', $normalizedLiveStreamId)->first();
        }

        if (!$resolvedStream) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid live_stream_id');
        }

        $normalizedLiveStreamId = (string) $resolvedStream->id;

        $item = new LiveStreamComments();
        $item->live_stream_id = $normalizedLiveStreamId;
        $item->sender_id = intval($request->sender_id);
        $item->receiver_id = $request->filled('receiver_id') ? intval($request->receiver_id) : null;
        $item->comment = $request->comment;
        $item->comment_type = $commentType;
        $item->gift_id = $request->filled('gift_id') ? intval($request->gift_id) : null;
        $item->save();
        GlobalFunction::autoUpgradeUserLevel(intval($request->sender_id));

        return GlobalFunction::sendSimpleResponse(true, 'Comment saved successfully');
    }

    public function startLiveStream(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }
        if (intval($user->is_host ?? 0) !== 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Only approved host can start live stream');
        }

        $validator = Validator::make($request->all(), [
            'category_id' => 'required|exists:tbl_categories,id',
            'sub_category_id' => 'required|exists:tbl_sub_categories,id',
            'topic_id' => 'required|exists:tbl_topics,id',
            'language_id' => 'required|exists:languages,id',
            'title' => 'nullable|string|max:255',
            'force' => 'nullable|in:0,1',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $subCategory = SubCategories::find($request->sub_category_id);
        if (!$subCategory || intval($subCategory->category_id) !== intval($request->category_id)) {
            return GlobalFunction::sendSimpleResponse(false, 'Selected sub category does not belong to category');
        }

        $topic = Topics::find($request->topic_id);
        if (
            !$topic ||
            intval($topic->sub_category_id) !== intval($request->sub_category_id) ||
            intval($topic->category_id) !== intval($request->category_id)
        ) {
            return GlobalFunction::sendSimpleResponse(false, 'Selected topic does not belong to category/sub category');
        }

        $activeStream = LiveStreams::where('user_id', $user->id)->where('status', 1)->first();
        if ($activeStream) {
            $forceStart = intval($request->force ?? 0) === 1;
            if (!$forceStart) {
                return GlobalFunction::sendDataResponse(false, 'Live stream already running', [
                    'live_stream_id' => intval($activeStream->id),
                    'started_at' => !empty($activeStream->started_at) ? Carbon::parse($activeStream->started_at)->format('Y-m-d H:i:s') : null,
                    'status' => intval($activeStream->status ?? 0),
                ]);
            }

            // Auto-end currently active stream when force=1
            $endedAt = Carbon::now();
            $startedAt = !empty($activeStream->started_at) ? Carbon::parse($activeStream->started_at) : $endedAt;
            $activeStream->ended_at = $endedAt;
            $activeStream->duration = max(0, $startedAt->diffInSeconds($endedAt));
            $activeStream->status = 0;
            $activeStream->save();
        }

        $stream = new LiveStreams();
        $stream->user_id = $user->id;
        $stream->category_id = $request->category_id;
        $stream->sub_category_id = $request->sub_category_id;
        $stream->topic_id = $request->topic_id;
        $stream->language_id = $request->language_id;
        $stream->title = $request->title;
        $stream->started_at = Carbon::now();
        $stream->status = 1;
        $stream->save();

        return GlobalFunction::sendDataResponse(true, 'Live stream started', [
            'id' => $stream->id,
            'category_id' => intval($stream->category_id),
            'sub_category_id' => intval($stream->sub_category_id),
            'topic_id' => intval($stream->topic_id),
            'language_id' => intval($stream->language_id),
            'started_at' => Carbon::parse($stream->started_at)->format('Y-m-d H:i:s'),
        ]);
    }

    public function endLiveStream(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'live_stream_id' => 'required|exists:tbl_live_streams,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $stream = LiveStreams::find($request->live_stream_id);
        if (!$stream || intval($stream->user_id) !== intval($user->id)) {
            return GlobalFunction::sendSimpleResponse(false, 'Live stream not found');
        }
        if (intval($stream->status) !== 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Live stream already ended');
        }

        $endedAt = Carbon::now();
        $startedAt = Carbon::parse($stream->started_at);
        $duration = $startedAt->diffInSeconds($endedAt);

        $stream->ended_at = $endedAt;
        $stream->duration = $duration;
        $stream->status = 0;
        $stream->save();

        return GlobalFunction::sendDataResponse(true, 'Live stream ended', [
            'id' => $stream->id,
            'duration' => intval($stream->duration),
            'started_at' => $startedAt->format('Y-m-d H:i:s'),
            'ended_at' => Carbon::parse($stream->ended_at)->format('Y-m-d H:i:s'),
        ]);
    }

    public function uploadLiveStreamRecording(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'live_stream_id' => 'required|exists:tbl_live_streams,id',
            'video' => 'required|file|mimetypes:video/mp4,video/quicktime,video/x-m4v|max:512000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $stream = LiveStreams::find($request->live_stream_id);
        if (!$stream || intval($stream->user_id) !== intval($user->id)) {
            return GlobalFunction::sendSimpleResponse(false, 'Live stream not found');
        }

        $path = GlobalFunction::saveFileAndGivePath($request->file('video'));
        $stream->video_url = $path;
        $stream->save();

        // Surface the recording as a Reel so it's discoverable on the Home
        // feed, not just the host's own Profile > My Lives.
        $post = new Posts();
        $post->user_id = $user->id;
        $post->post_type = Constants::postTypeReel;
        $post->can_comment = 1;
        $post->video = $path;
        if (!empty($stream->thumbnail)) {
            $post->thumbnail = $stream->thumbnail;
        } elseif (!empty($user->profile_photo)) {
            $post->thumbnail = $user->profile_photo;
        }
        if (!empty($stream->title)) {
            $post->description = $stream->title;
        }
        $post->save();

        return GlobalFunction::sendDataResponse(true, 'Recording uploaded successfully', [
            'id' => $stream->id,
            'video_url' => GlobalFunction::generateFileUrl($path),
        ]);
    }

    public function deleteLiveHistory(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'live_stream_id' => 'required|exists:tbl_live_streams,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $stream = LiveStreams::find($request->live_stream_id);
        if (!$stream || intval($stream->user_id) !== intval($user->id)) {
            return GlobalFunction::sendSimpleResponse(false, 'Live stream not found');
        }
        if (intval($stream->status) === 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Cannot delete a live session that is still live');
        }

        if (!empty($stream->video_url)) {
            GlobalFunction::deleteFile($stream->video_url);
        }

        $stream->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Live history deleted successfully');
    }

    public function fetchRecordedLives(Request $request)
    {
        $token = $request->header('authtoken');
        $authUser = GlobalFunction::getUserFromAuthToken($token);
        if (!$authUser) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($authUser->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'category_id' => 'nullable|integer|exists:tbl_categories,id',
            'last_item_id' => 'nullable|integer|min:1',
            'limit' => 'nullable|integer|min:1|max:100',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $limit = intval($request->limit ?? 20);

        $query = LiveStreams::whereNotNull('video_url')
            ->where('video_url', '!=', '')
            ->orderBy('id', 'DESC')
            ->limit($limit);

        if ($request->filled('category_id')) {
            $query->where('category_id', intval($request->category_id));
        }
        if ($request->filled('last_item_id')) {
            $query->where('id', '<', intval($request->last_item_id));
        }

        $rows = $query->get();

        if ($rows->isEmpty()) {
            return GlobalFunction::sendDataResponse(true, 'Success', []);
        }

        $userIds = $rows->pluck('user_id')->unique()->values()->all();
        $hosts = Users::whereIn('id', $userIds)
            ->get(['id', 'username', 'fullname', 'profile_photo', 'is_verify'])
            ->keyBy('id');

        $categoryIds = $rows->pluck('category_id')->filter()->unique()->values()->all();
        $categoryNames = empty($categoryIds) ? collect() : Categories::whereIn('id', $categoryIds)->pluck('name', 'id');

        $data = $rows->map(function ($item) use ($hosts, $categoryNames) {
            $host = $hosts->get($item->user_id);
            return [
                'id' => intval($item->id),
                'user_id' => intval($item->user_id),
                'title' => $item->title,
                // No thumbnail-capture pipeline exists yet — left null rather
                // than fabricated. video_url is real once a recording has
                // been uploaded for this session.
                'thumbnail' => null,
                'video_url' => GlobalFunction::generateFileUrl($item->video_url),
                'duration' => intval($item->duration ?? 0),
                'category_id' => $item->category_id ? intval($item->category_id) : null,
                'category_name' => $item->category_id ? ($categoryNames[$item->category_id] ?? null) : null,
                'host_username' => $host->username ?? null,
                'host_fullname' => $host->fullname ?? null,
                'host_profile_photo' => ($host && !empty($host->profile_photo))
                    ? GlobalFunction::generateFileUrl($host->profile_photo)
                    : null,
                'host_is_verify' => $host ? intval($host->is_verify ?? 0) : 0,
                'created_at' => !empty($item->created_at) ? Carbon::parse($item->created_at)->format('Y-m-d H:i:s') : null,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Success', $data);
    }

    public function fetchMyLives(Request $request)
    {
        $token = $request->header('authtoken');
        $authUser = GlobalFunction::getUserFromAuthToken($token);
        if (!$authUser) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($authUser->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'user_id' => 'nullable|exists:tbl_users,id',
            'last_item_id' => 'nullable|integer|min:1',
            'limit' => 'nullable|integer|min:1|max:100',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $limit = intval($request->limit ?? 20);
        $targetUserId = intval($request->user_id ?? $authUser->id);
        $query = LiveStreams::where('user_id', $targetUserId)
            ->orderBy('id', 'DESC')
            ->limit($limit);

        if ($request->filled('last_item_id')) {
            $query->where('id', '<', intval($request->last_item_id));
        }

        $rows = $query->get();

        if ($rows->isEmpty()) {
            return GlobalFunction::sendDataResponse(true, 'Success', []);
        }

        $streamIds = $rows->pluck('id')->map(fn ($id) => (string) $id)->all();

        // Gift count + stars (coin value) earned per session — real, permanent
        // rows written while the stream is live (never touched by the
        // Firestore cleanup that runs when a stream ends).
        $giftStats = LiveStreamComments::query()
            ->join('tbl_gifts', 'tbl_gifts.id', '=', 'tbl_live_stream_comments.gift_id')
            ->whereIn('tbl_live_stream_comments.live_stream_id', $streamIds)
            ->where('tbl_live_stream_comments.comment_type', 'GIFT')
            ->groupBy('tbl_live_stream_comments.live_stream_id')
            ->selectRaw('tbl_live_stream_comments.live_stream_id, COUNT(*) as gift_count, SUM(tbl_gifts.coin_price) as stars_earned')
            ->get()
            ->keyBy('live_stream_id');

        // Unique viewers per session (audience + co-host joins)
        $viewerStats = LiveStreamComments::whereIn('live_stream_id', $streamIds)
            ->whereIn('comment_type', ['JOINED', 'JOINED_CO_HOST'])
            ->groupBy('live_stream_id')
            ->selectRaw('live_stream_id, COUNT(DISTINCT sender_id) as viewer_count')
            ->get()
            ->keyBy('live_stream_id');

        // Text comment count per session
        $commentStats = LiveStreamComments::whereIn('live_stream_id', $streamIds)
            ->where('comment_type', 'TEXT')
            ->groupBy('live_stream_id')
            ->selectRaw('live_stream_id, COUNT(*) as comment_count')
            ->get()
            ->keyBy('live_stream_id');

        // Followers gained per session — count of follows landing inside that
        // session's [started_at, ended_at] window. A host can't have two
        // overlapping sessions, so this window is unambiguous.
        $followersGainedByStream = [];
        if (Schema::hasColumn('tbl_followers', 'created_at')) {
            $earliestStart = $rows->min('started_at');
            $followerTimestamps = Followers::where('to_user_id', $targetUserId)
                ->when($earliestStart, fn ($q) => $q->where('created_at', '>=', $earliestStart))
                ->pluck('created_at');

            foreach ($rows as $row) {
                if (empty($row->started_at)) {
                    continue;
                }
                $start = Carbon::parse($row->started_at);
                $end = !empty($row->ended_at) ? Carbon::parse($row->ended_at) : Carbon::now();
                $count = 0;
                foreach ($followerTimestamps as $ts) {
                    if (Carbon::parse($ts)->between($start, $end)) {
                        $count++;
                    }
                }
                $followersGainedByStream[$row->id] = $count;
            }
        }

        $data = $rows->map(function ($item) use ($giftStats, $viewerStats, $commentStats, $followersGainedByStream) {
            $idKey = (string) $item->id;
            $gift = $giftStats->get($idKey);
            $viewer = $viewerStats->get($idKey);
            $comment = $commentStats->get($idKey);

            return [
                'id' => intval($item->id),
                'user_id' => intval($item->user_id),
                'title' => $item->title,
                // No thumbnail-capture pipeline exists yet — left null rather
                // than fabricated. video_url is real once a recording has
                // been uploaded for this session.
                'thumbnail' => null,
                'video_url' => GlobalFunction::generateFileUrl($item->video_url ?? null),
                'viewer_count' => $viewer ? intval($viewer->viewer_count) : 0,
                'duration' => intval($item->duration ?? 0),
                'total_gifts' => $gift ? intval($gift->gift_count) : 0,
                'stars_earned' => $gift ? intval($gift->stars_earned) : 0,
                'total_comments' => $comment ? intval($comment->comment_count) : 0,
                'followers_gained' => $followersGainedByStream[$item->id] ?? null,
                'started_at' => !empty($item->started_at) ? Carbon::parse($item->started_at)->format('Y-m-d H:i:s') : null,
                'ended_at' => !empty($item->ended_at) ? Carbon::parse($item->ended_at)->format('Y-m-d H:i:s') : null,
                'status' => intval($item->status ?? 0),
                'created_at' => !empty($item->created_at) ? Carbon::parse($item->created_at)->format('Y-m-d H:i:s') : null,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Success', $data);
    }

    public function fetchMyLiveStats(Request $request)
    {
        $token = $request->header('authtoken');
        $authUser = GlobalFunction::getUserFromAuthToken($token);
        if (!$authUser) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($authUser->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $liveStreamIds = LiveStreams::where('user_id', $authUser->id)->pluck('id');

        $totalDuration = LiveStreams::where('user_id', $authUser->id)->sum('duration');
        $totalComments = $liveStreamIds->isEmpty()
            ? 0
            : DB::table('tbl_live_stream_comments')
                ->whereIn('live_stream_id', $liveStreamIds->map(fn ($id) => (string) $id)->all())
                ->count();

        $data = [
            'duration' => intval($totalDuration),
            'followers' => intval($authUser->follower_count ?? 0),
            'calls' => null,
            'calls_available' => false,
            'geo_diamond' => intval($authUser->diamond_wallet ?? 0),
            'comments' => intval($totalComments),
        ];

        return GlobalFunction::sendDataResponse(true, 'Success', $data);
    }

    public function liveStreamingList()
    {
        $categories = Categories::where('status', 1)->orderBy('name')->get(['id', 'name']);
        $subCategories = SubCategories::where('status', 1)->orderBy('name')->get(['id', 'name', 'category_id']);
        $topics = Topics::where('status', 1)->orderBy('name')->get(['id', 'name', 'sub_category_id']);
        $languages = Language::orderBy('title')->get(['id', 'title', 'code']);
        $users = Users::orderBy('username')->get(['id', 'username', 'fullname']);

        return view('liveStreams', compact('categories', 'subCategories', 'topics', 'languages', 'users'));
    }

    public function listLiveStreams(Request $request)
    {
        $query = LiveStreams::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');
        $filterDate = trim((string) $request->input('filter_date'));
        $filterCategoryId = $request->input('category_id');
        $filterSubCategoryId = $request->input('sub_category_id');
        $filterTopicId = $request->input('topic_id');
        $filterLanguageId = $request->input('language_id');
        $filterUserId = $request->input('user_id');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('title', 'LIKE', "%{$searchValue}%")
                    ->orWhere('id', 'LIKE', "%{$searchValue}%");
            });
        }

        if (!empty($filterDate)) {
            $query->whereDate('started_at', $filterDate);
        }
        if (!empty($filterCategoryId)) {
            $query->where('category_id', intval($filterCategoryId));
        }
        if (!empty($filterSubCategoryId)) {
            $query->where('sub_category_id', intval($filterSubCategoryId));
        }
        if (!empty($filterTopicId)) {
            $query->where('topic_id', intval($filterTopicId));
        }
        if (!empty($filterLanguageId)) {
            $query->where('language_id', intval($filterLanguageId));
        }
        if (!empty($filterUserId)) {
            $query->where('user_id', intval($filterUserId));
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $categoryNames = Categories::pluck('name', 'id');
        $subCategoryNames = SubCategories::pluck('name', 'id');
        $topicNames = Topics::pluck('name', 'id');
        $languageNames = Language::select('id', 'title', 'code')->get()->mapWithKeys(function ($item) {
            return [$item->id => ($item->title ?? $item->code)];
        });

        $data = $result->map(function ($item) use ($categoryNames, $subCategoryNames, $topicNames, $languageNames) {
            $user = GlobalFunction::createUserDetailsColumn($item->user_id);

            $learning = "<div>
                <p class='m-0'><strong>Category:</strong> " . ($categoryNames[$item->category_id] ?? '-') . "</p>
                <p class='m-0'><strong>Sub Category:</strong> " . ($subCategoryNames[$item->sub_category_id] ?? '-') . "</p>
                <p class='m-0'><strong>Topic:</strong> " . ($topicNames[$item->topic_id] ?? '-') . "</p>
                <p class='m-0'><strong>Language:</strong> " . ($languageNames[$item->language_id] ?? '-') . "</p>
            </div>";

            $statusBadge = intval($item->status) === 1
                ? "<span class='badge bg-success'>LIVE</span>"
                : "<span class='badge bg-secondary'>ENDED</span>";

            $startedAt = !empty($item->started_at) ? Carbon::parse($item->started_at)->format('Y-m-d H:i:s') : '-';
            $endedAt = !empty($item->ended_at) ? Carbon::parse($item->ended_at)->format('Y-m-d H:i:s') : '-';
            $activitiesUrl = route('liveStreamActivities', ['liveStreamId' => $item->id]);
            $activitiesBtn = "<a href='{$activitiesUrl}'
                class='btn border rounded-2 text-primary d-inline-flex align-items-center justify-content-center'>
                <i class='mdi mdi-eye me-1'></i> View Activities
                </a>";

            return [
                "#{$item->id}",
                $user,
                $item->title ?? '-',
                $learning,
                $startedAt,
                $endedAt,
                intval($item->duration),
                $statusBadge,
                $activitiesBtn,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function liveStreamActivities($liveStreamId)
    {
        $stream = LiveStreams::find($liveStreamId);
        if (!$stream) {
            return redirect()->back();
        }

        return view('liveStreamActivities', [
            'stream' => $stream,
        ]);
    }

    public function listLiveStreamActivities(Request $request)
    {
        $streamId = trim((string) $request->input('live_stream_id'));
        if (empty($streamId)) {
            return response()->json([
                'draw' => intval($request->input('draw')),
                'recordsTotal' => 0,
                'recordsFiltered' => 0,
                'data' => [],
            ]);
        }

        $query = LiveStreamComments::where(function ($q) use ($streamId) {
            $q->where('live_stream_id', $streamId)
                ->orWhereRaw('TRIM(live_stream_id) = ?', [$streamId]);
        });
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('comment_type', 'LIKE', "%{$searchValue}%")
                    ->orWhere('comment', 'LIKE', "%{$searchValue}%")
                    ->orWhere('sender_id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('receiver_id', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $giftPrices = Gifts::pluck('coin_price', 'id');

        $data = $result->map(function ($item) use ($giftPrices) {
            $sender = GlobalFunction::createUserDetailsColumn($item->sender_id);
            $receiver = !empty($item->receiver_id) ? GlobalFunction::createUserDetailsColumn($item->receiver_id) : '-';
            $gift = '-';
            if (!empty($item->gift_id)) {
                $giftPrice = $giftPrices[$item->gift_id] ?? null;
                $gift = !is_null($giftPrice)
                    ? ('#' . $item->gift_id . ' (' . intval($giftPrice) . ' stars)')
                    : ('#' . $item->gift_id);
            }
            $commentType = "<span class='badge bg-info'>" . e($item->comment_type) . "</span>";
            $comment = !empty($item->comment) ? e($item->comment) : '-';
            $createdAt = !empty($item->created_at) ? Carbon::parse($item->created_at)->format('Y-m-d H:i:s') : '-';

            return [
                $item->id,
                $commentType,
                $sender,
                $receiver,
                $comment,
                $gift,
                $createdAt,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    function dummyLives(){
        $dummyUsers = Users::where('is_dummy', 1)->get();
        $categories = Categories::where('status', 1)->orderBy('name')->get(['id', 'name']);
        $subCategories = SubCategories::where('status', 1)->orderBy('name')->get(['id', 'name', 'category_id']);
        $topics = Topics::where('status', 1)->orderBy('name')->get(['id', 'name', 'sub_category_id', 'category_id']);
        $languages = Language::orderBy('title')->get(['id', 'title']);
        return view('dummyLives',[
            'dummyUsers' => $dummyUsers,
            'categories' => $categories,
            'subCategories' => $subCategories,
            'topics' => $topics,
            'languages' => $languages,
        ]);
    }

    function addDummyLive(Request $request){
        if (!$this->hasDummyLiveLearningColumns()) {
            return GlobalFunction::sendSimpleResponse(false, 'Please run migration for Dummy Lives learning fields (category/sub category/topic/language)');
        }

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:tbl_users,id',
            'category_id' => 'required|exists:tbl_categories,id',
            'sub_category_id' => 'required|exists:tbl_sub_categories,id',
            'topic_id' => 'required|exists:tbl_topics,id',
            'language_id' => 'required|exists:languages,id',
            'title' => 'required|string|max:255',
            'link' => 'required|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }
        $subCategory = SubCategories::find($request->sub_category_id);
        if (!$subCategory || intval($subCategory->category_id) !== intval($request->category_id)) {
            return GlobalFunction::sendSimpleResponse(false, 'Selected sub category does not belong to category');
        }
        $topic = Topics::find($request->topic_id);
        if (
            !$topic
            || intval($topic->sub_category_id) !== intval($request->sub_category_id)
            || intval($topic->category_id) !== intval($request->category_id)
        ) {
            return GlobalFunction::sendSimpleResponse(false, 'Selected topic does not belong to sub category');
        }

        $item = new DummyLiveVideos();
        $item->user_id = $request->user_id;
        $item->category_id = $request->category_id;
        $item->sub_category_id = $request->sub_category_id;
        $item->topic_id = $request->topic_id;
        $item->language_id = $request->language_id;
        $item->title = $request->title;
        $item->link = $request->link;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Dummy live added successfully');
    }

    function deleteDummyLive(Request $request){
        $item = DummyLiveVideos::find($request->id);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Dummy live deleted successfully');
    }

    function changeDummyLiveStatus(Request $request){
        $coinPackage = DummyLiveVideos::find($request->id);
        $coinPackage->status = $request->status;
        $coinPackage->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }

    public function listDummyLives(Request $request)
    {
        $query = DummyLiveVideos::query();
        $totalData = $query->count();
        $hasLearningColumns = $this->hasDummyLiveLearningColumns();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('title', 'LIKE', "%{$searchValue}%")
                ->orwhere('link', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $categoryNames = $hasLearningColumns ? Categories::pluck('name', 'id') : collect();
        $subCategoryNames = $hasLearningColumns ? SubCategories::pluck('name', 'id') : collect();
        $topicNames = $hasLearningColumns ? Topics::pluck('name', 'id') : collect();
        $languageNames = $hasLearningColumns ? Language::pluck('title', 'id') : collect();

        $data = $result->map(function ($item) use ($categoryNames, $subCategoryNames, $topicNames, $languageNames, $hasLearningColumns){

            $user = GlobalFunction::createUserDetailsColumn($item->user_id);
            $categoryName = $hasLearningColumns ? ($categoryNames[$item->category_id] ?? '-') : '-';
            $subCategoryName = $hasLearningColumns ? ($subCategoryNames[$item->sub_category_id] ?? '-') : '-';
            $topicName = $hasLearningColumns ? ($topicNames[$item->topic_id] ?? '-') : '-';
            $languageName = $hasLearningColumns ? ($languageNames[$item->language_id] ?? '-') : '-';
            $categoryId = $hasLearningColumns ? ($item->category_id ?? '') : '';
            $subCategoryId = $hasLearningColumns ? ($item->sub_category_id ?? '') : '';
            $topicId = $hasLearningColumns ? ($item->topic_id ?? '') : '';
            $languageId = $hasLearningColumns ? ($item->language_id ?? '') : '';

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-userid='{$item->user_id}'
                        data-categoryid='{$categoryId}'
                        data-subcategoryid='{$subCategoryId}'
                        data-topicid='{$topicId}'
                        data-languageid='{$languageId}'
                        data-title='{$item->title}'
                        data-link='{$item->link}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            $checked = $item->status == 1 ? 'checked' : '';
            $status = "<input type='checkbox' id='dummyLiveStatus-{$item->id}' rel='{$item->id}' class='onOffDummyLive' {$checked} data-switch='none'/>
                    <label for='dummyLiveStatus-{$item->id}'></label>";

            return [
                $user,
                $categoryName,
                $subCategoryName,
                $topicName,
                $languageName,
                $item->title,
                $item->link,
                $status,
                $action
            ];
        });

        $json_data = [
            "draw" => intval($request->input('draw')),
            "recordsTotal" => intval($totalData),
            "recordsFiltered" => intval($totalFiltered),
            "data" => $data,
        ];

        return response()->json($json_data);
    }

    function editDummyLive(Request $request){
        if (!$this->hasDummyLiveLearningColumns()) {
            return GlobalFunction::sendSimpleResponse(false, 'Please run migration for Dummy Lives learning fields (category/sub category/topic/language)');
        }

        $validator = Validator::make($request->all(), [
            'id' => 'required',
            'category_id' => 'required|exists:tbl_categories,id',
            'sub_category_id' => 'required|exists:tbl_sub_categories,id',
            'topic_id' => 'required|exists:tbl_topics,id',
            'language_id' => 'required|exists:languages,id',
            'title' => 'required|string|max:255',
            'link' => 'required|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }
        $subCategory = SubCategories::find($request->sub_category_id);
        if (!$subCategory || intval($subCategory->category_id) !== intval($request->category_id)) {
            return GlobalFunction::sendSimpleResponse(false, 'Selected sub category does not belong to category');
        }
        $topic = Topics::find($request->topic_id);
        if (
            !$topic
            || intval($topic->sub_category_id) !== intval($request->sub_category_id)
            || intval($topic->category_id) !== intval($request->category_id)
        ) {
            return GlobalFunction::sendSimpleResponse(false, 'Selected topic does not belong to sub category');
        }

        $dummyLive = DummyLiveVideos::find($request->id);
        $dummyLive->category_id = $request->category_id;
        $dummyLive->sub_category_id = $request->sub_category_id;
        $dummyLive->topic_id = $request->topic_id;
        $dummyLive->language_id = $request->language_id;
        $dummyLive->title = $request->title;
        $dummyLive->link = $request->link;
        $dummyLive->save();

        return GlobalFunction::sendSimpleResponse(true, 'Dummy live updated successfully!');
    }
}
