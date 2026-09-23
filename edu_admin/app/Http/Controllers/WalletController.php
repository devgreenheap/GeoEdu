<?php

namespace App\Http\Controllers;

use App\Models\CoinPackages;
use App\Models\Constants;
use App\Models\Coupons;
use App\Models\DiamondBuyingInformation;
use App\Models\DiamondFaq;
use App\Models\DiamondPackages;
use App\Models\DiamondSpendHistory;
use App\Models\DiamondTransactions;
use App\Models\AgentCommissionEntries;
use App\Models\EntryEffects;
use App\Models\Banner;
use App\Models\GiftCategory;
use App\Models\GifterReturnWallet;
use App\Models\Gifts;
use App\Models\GlobalFunction;
use App\Models\GlobalSettings;
use App\Models\ManualPayout;
use App\Models\RedeemRequests;
use App\Models\StateMaster;
use App\Models\UserEntryEffects;
use App\Models\UserRoleRequests;
use App\Models\Users;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Validator;
use Throwable;

use function Psy\debug;

class WalletController extends Controller
{
    //
    private function resolveStateAgentIdByAgentId(int $agentId): int
    {
        if ($agentId <= 0) {
            return 0;
        }

        $agent = Users::select('id', 'state')->find($agentId);
        if (!$agent) {
            return 0;
        }

        $agentState = trim((string) ($agent->state ?? ''));
        if ($agentState === '') {
            return 0;
        }

        $stateRow = null;
        if (ctype_digit($agentState)) {
            $stateRow = StateMaster::find(intval($agentState));
        }

        if (!$stateRow) {
            $stateRow = StateMaster::whereRaw('LOWER(TRIM(name)) = ?', [strtolower($agentState)])->first();
        }

        return intval($stateRow->agent_id ?? 0);
    }

    private function resolvePeriodRange(?string $period): array
    {
        $period = strtolower(trim((string) $period));
        $now = Carbon::now();

        switch ($period) {
            case 'all_time':
                $start = Carbon::createFromTimestamp(0);
                $end = $now->copy()->endOfDay();
                break;
            case 'yesterday':
                $start = $now->copy()->subDay()->startOfDay();
                $end = $now->copy()->subDay()->endOfDay();
                break;
            case 'this_week':
                $start = $now->copy()->startOfWeek();
                $end = $now->copy()->endOfWeek();
                break;
            case 'this_month':
                $start = $now->copy()->startOfMonth();
                $end = $now->copy()->endOfMonth();
                break;
            case 'today':
            default:
                $start = $now->copy()->startOfDay();
                $end = $now->copy()->endOfDay();
                break;
        }

        return [$start, $end];
    }

    private function submitRoleRequest(Request $request, int $requestType, string $successMessage)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        if ($requestType === Constants::roleRequestHost && intval($user->is_host ?? 0) === 1) {
            return GlobalFunction::sendSimpleResponse(false, 'User is already a host');
        }
        if ($requestType === Constants::roleRequestAgent && intval($user->is_agent ?? 0) === 1) {
            return GlobalFunction::sendSimpleResponse(false, 'User is already an agent');
        }

        $pendingRequest = UserRoleRequests::where('user_id', $user->id)
            ->where('request_type', $requestType)
            ->where('status', Constants::roleRequestPending)
            ->first();
        if ($pendingRequest) {
            return GlobalFunction::sendSimpleResponse(false, 'Request already submitted and pending approval');
        }

        $roleRequest = new UserRoleRequests();
        $roleRequest->user_id = $user->id;
        $roleRequest->request_type = $requestType;
        $roleRequest->status = Constants::roleRequestPending;
        $roleRequest->requested_at = Carbon::now();
        $roleRequest->save();

        if ($requestType === Constants::roleRequestHost) {
            $this->notifyAssignedAgentForHostRequest($user, $roleRequest->id);
        }

        return GlobalFunction::sendSimpleResponse(true, $successMessage);
    }

    private function notifyAssignedAgentForHostRequest($requestUser, int $roleRequestId): void
    {
        try {
            $agentId = intval($requestUser->agent_id ?? 0);
            if ($agentId <= 0) {
                return;
            }

            $agent = Users::where('id', $agentId)
                ->where('is_agent', 1)
                ->first();
            if (!$agent) {
                return;
            }

            $notificationData = GlobalFunction::insertUserNotification(
                Constants::notify_host_request_agent,
                $requestUser->id,
                $agent->id,
                $roleRequestId
            );

            if (empty($agent->device_token)) {
                return;
            }

            $userName = trim((string) ($requestUser->fullname ?: $requestUser->username ?: ('User #' . $requestUser->id)));
            $title = 'Host Access Request';
            $description = $userName . ' requested host access';

            $pushData = [
                'screen' => 'agent_users',
                'route' => 'agent_users',
                'request_type' => 'host_access',
                'request_id' => (string) $roleRequestId,
                'user_id' => (string) $requestUser->id,
            ];

            if ($notificationData) {
                $pushData['notification_id'] = (string) $notificationData->id;
                $pushData['notify_type'] = (string) Constants::notify_host_request_agent;
            }

            $payload = GlobalFunction::generatePushNotificationPayload(
                $agent->device,
                Constants::pushTypeToken,
                $agent->device_token,
                $title,
                $description,
                null,
                $pushData
            );

            GlobalFunction::sendPushNotification($payload);
        } catch (Throwable $e) {
            Log::error('Host request agent notification failed', [
                'request_user_id' => $requestUser->id ?? null,
                'role_request_id' => $roleRequestId,
                'error' => $e->getMessage(),
            ]);
        }
    }

    private function createDiamondTransaction($user, $type, $diamonds, $source = null, $referenceType = null, $referenceId = null, $note = null, $extra = [])
    {
        $transaction = new DiamondTransactions();
        $transaction->user_id = $user->id;
        $transaction->type = $type;
        $transaction->diamonds = $diamonds;
        $transaction->balance_after = $user->diamond_wallet ?? 0;
        $transaction->source = $source;
        $transaction->reference_type = $referenceType;
        $transaction->reference_id = $referenceId;
        $transaction->note = $note;
        $transaction->payment_id = $extra['payment_id'] ?? null;
        $transaction->order_id = $extra['order_id'] ?? null;
        $transaction->signature = $extra['signature'] ?? null;
        $transaction->diamond_pack_id = $extra['diamond_pack_id'] ?? null;
        $transaction->amount = $extra['amount'] ?? null;
        $transaction->status = $extra['status'] ?? null;
        $transaction->save();

        return $transaction;
    }

    public function fetchDiamondPackages()
    {
        $packages = DiamondPackages::where('status', 1)
            ->orderBy('id', 'DESC')
            ->get()
            ->map(function ($item) {
                $originalPrice = floatval($item->diamond_plan_price);
                $discountedPrice = !is_null($item->discounted_price) ? floatval($item->discounted_price) : $originalPrice;
                return [
                    'id' => $item->id,
                    'image' => $item->image,
                    'diamonds' => intval($item->diamond_amount),
                    'original_price' => $originalPrice,
                    'discounted_price' => $discountedPrice,
                    'offer_entry_effect_id' => !is_null($item->offer_entry_effect_id) ? intval($item->offer_entry_effect_id) : null,
                    'button_text' => 'Buy For',
                    'status' => $item->status,
                ];
            })
            ->values();

        return GlobalFunction::sendDataResponse(true, 'Diamond packages fetched successfully', $packages);
    }

    public function fetchBanners(Request $request)
    {
        $type = strtolower(trim((string) ($request->type ?? 'homepage')));
        if ($type === 'home') {
            $type = 'homepage';
        }

        if (!in_array($type, ['homepage', 'audio', 'all'], true)) {
            return GlobalFunction::sendSimpleResponse(false, 'Type must be homepage, audio, or all');
        }

        $query = Banner::query()->orderBy('id', 'DESC');
        if ($type !== 'all') {
            $query->where('type', $type);
        }

        $items = $query->get()->map(function ($item) {
            return [
                'id' => intval($item->id),
                'type' => $item->type,
                'image' => $item->image,
                'image_url' => GlobalFunction::generateFileUrl($item->image),
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Banners fetched successfully', $items);
    }

    public function fetchEntryEffects(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $entryEffects = EntryEffects::orderBy('id', 'DESC')->get()->map(function ($item) {
            return [
                'id' => $item->id,
                'title' => $item->title,
                'coin_price' => intval($item->coin_price),
                'duration' => intval($item->duration),
                'image' => GlobalFunction::generateFileUrl($item->image),
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Entry effects fetched successfully', $entryEffects);
    }

    public function fetchDiamondBuyingInformation()
    {
        $items = DiamondBuyingInformation::orderBy('id', 'ASC')->get()->map(function ($item, $index) {
            return [
                'id' => intval($item->id),
                'point_no' => $index + 1,
                'information' => $item->information,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Diamond buying information fetched successfully', $items);
    }

    public function fetchDiamondFaqs()
    {
        $request = request();
        $category = strtolower(trim((string) ($request->category ?? 'diamond')));
        if (!in_array($category, ['diamond', 'payment', 'withdrawal', 'gift', 'general'], true)) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid FAQ category');
        }

        $items = DiamondFaq::where('category', $category)->orderBy('id', 'ASC')->get()->map(function ($item) {
            return [
                'id' => intval($item->id),
                'category' => (string) ($item->category ?? $category),
                'question' => $item->question,
                'answer' => $item->answer,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'FAQs fetched successfully', $items);
    }

    public function fetchPaymentFaqs()
    {
        $items = DiamondFaq::where('category', 'payment')->orderBy('id', 'ASC')->get()->map(function ($item) {
            return [
                'id' => intval($item->id),
                'category' => (string) ($item->category ?? 'payment'),
                'question' => $item->question,
                'answer' => $item->answer,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Payment FAQs fetched successfully', $items);
    }

    public function fetchFaqs(Request $request)
    {
        $category = strtolower(trim((string) ($request->category ?? 'diamond')));
        if (!in_array($category, ['diamond', 'payment', 'withdrawal', 'gift', 'general'], true)) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid FAQ category');
        }

        $items = DiamondFaq::where('category', $category)->orderBy('id', 'ASC')->get()->map(function ($item) {
            return [
                'id' => intval($item->id),
                'category' => (string) ($item->category ?? 'general'),
                'question' => $item->question,
                'answer' => $item->answer,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'FAQs fetched successfully', $items);
    }

    public function buyEntryEffect(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $rules = [
            'entry_effect_id' => 'required|exists:tbl_entry_effects,id',
            'diamonds' => 'required|integer|min:1',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $entryEffect = EntryEffects::find($request->entry_effect_id);
        $requiredDiamonds = intval($entryEffect->coin_price);
        $requestedDiamonds = intval($request->diamonds);

        if ($requestedDiamonds !== $requiredDiamonds) {
            return GlobalFunction::sendSimpleResponse(false, 'diamond amount mismatch for selected entry effect');
        }

        if (intval($user->diamond_wallet ?? 0) < $requiredDiamonds) {
            return GlobalFunction::sendSimpleResponse(false, 'insufficient diamonds in wallet');
        }

        $user->diamond_wallet = intval($user->diamond_wallet ?? 0) - $requiredDiamonds;
        $user->diamond_spent_lifetime = intval($user->diamond_spent_lifetime ?? 0) + $requiredDiamonds;
        $user->save();

        $transaction = $this->createDiamondTransaction(
            $user,
            Constants::debit,
            $requiredDiamonds,
            'entry_effect_purchase',
            'entry_effect',
            $entryEffect->id,
            'Entry effect purchased'
        );

        $spend = new DiamondSpendHistory();
        $spend->user_id = $user->id;
        $spend->diamonds = $requiredDiamonds;
        $spend->purpose = 'entry_effect_purchase';
        $spend->reference_type = 'entry_effect';
        $spend->reference_id = $entryEffect->id;
        $spend->transaction_id = $transaction->id;
        $spend->note = 'Entry effect purchase';
        $spend->save();

        $purchasedAt = Carbon::now();
        $expiresAt = $purchasedAt->copy()->addHours(intval($entryEffect->duration));

        $purchase = new UserEntryEffects();
        $purchase->user_id = $user->id;
        $purchase->entry_effect_id = $entryEffect->id;
        $purchase->coin_price = $requiredDiamonds;
        $purchase->duration = intval($entryEffect->duration);
        $purchase->image = $entryEffect->image;
        $purchase->purchased_at = $purchasedAt;
        $purchase->expires_at = $expiresAt;
        $purchase->is_active = 1;
        $purchase->save();

        $user = GlobalFunction::prepareUserFullData($user->id);
        return GlobalFunction::sendDataResponse(true, 'Entry effect purchased successfully', [
            'diamond_wallet' => intval($user->diamond_wallet ?? 0),
            'user' => $user,
        ]);
    }

    public function fetchMyEntryEffects(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $rules = [
            'limit' => 'required|integer|min:1|max:100',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        UserEntryEffects::where('user_id', $user->id)
            ->where('is_active', 1)
            ->whereNotNull('expires_at')
            ->where('expires_at', '<', Carbon::now())
            ->update(['is_active' => 0]);

        $query = UserEntryEffects::where('user_id', $user->id)->orderBy('id', 'DESC')->limit($request->limit);
        if ($request->has('last_item_id') && !empty($request->last_item_id)) {
            $query->where('id', '<', $request->last_item_id);
        }

        $items = $query->get()->map(function ($item) {
            $isActive = intval($item->is_active) === 1 && (!empty($item->expires_at) ? Carbon::parse($item->expires_at)->greaterThan(Carbon::now()) : true);
            return [
                'id' => $item->id,
                'entry_effect_id' => $item->entry_effect_id,
                'coin_price' => intval($item->coin_price),
                'duration' => intval($item->duration),
                'image' => GlobalFunction::generateFileUrl($item->image),
                'purchased_at' => !empty($item->purchased_at) ? Carbon::parse($item->purchased_at)->format('Y-m-d H:i:s') : null,
                'expires_at' => !empty($item->expires_at) ? Carbon::parse($item->expires_at)->format('Y-m-d H:i:s') : null,
                'is_active' => $isActive,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Entry effects fetched successfully', $items);
    }

    public function requestBecomeHost(Request $request)
    {
        return $this->submitRoleRequest($request, Constants::roleRequestHost, 'Host request submitted successfully');
    }

    public function approveHost(Request $request)
    {
        $token = $request->header('authtoken');
        $agent = GlobalFunction::getUserFromAuthToken($token);
        if (!$agent) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($agent->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }
        if (intval($agent->is_agent ?? 0) !== 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Only agent can approve host');
        }

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|integer|exists:tbl_users,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $targetUser = Users::find(intval($request->user_id));
        if (!$targetUser) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }

        if (intval($targetUser->agent_id ?? 0) !== intval($agent->id)) {
            return GlobalFunction::sendSimpleResponse(false, 'You are not allowed to approve this user');
        }

        $pendingHostRequest = UserRoleRequests::where('user_id', $targetUser->id)
            ->where('request_type', Constants::roleRequestHost)
            ->where('status', Constants::roleRequestPending)
            ->orderBy('id', 'DESC')
            ->first();
        if (!$pendingHostRequest) {
            return GlobalFunction::sendSimpleResponse(false, 'Host request not found');
        }

        DB::transaction(function () use ($targetUser, $pendingHostRequest) {
            $targetUser->is_host = 1;
            $targetUser->save();

            $pendingHostRequest->status = Constants::roleRequestAccepted;
            $pendingHostRequest->action_at = Carbon::now();
            $pendingHostRequest->save();
        });

        return GlobalFunction::sendSimpleResponse(true, 'Host approved successfully');
    }

    public function requestBecomeAgent(Request $request)
    {
        return $this->submitRoleRequest($request, Constants::roleRequestAgent, 'Agent request submitted successfully');
    }

    public function fetchMyDiamondWallet(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        return GlobalFunction::sendDataResponse(true, 'Diamond wallet fetched successfully', [
            'diamond_wallet' => intval($user->diamond_wallet ?? 0),
            'diamond_collected_lifetime' => intval($user->diamond_collected_lifetime ?? 0),
            'diamond_spent_lifetime' => intval($user->diamond_spent_lifetime ?? 0),
            'diamond_purchased_lifetime' => intval($user->diamond_purchased_lifetime ?? 0),
        ]);
    }

    public function fetchMyDiamondTransactions(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $rules = [
            'limit' => 'required|integer|min:1|max:100',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $query = DiamondTransactions::where('user_id', $user->id)->orderBy('id', 'DESC')->limit($request->limit);
        if ($request->has('last_item_id')) {
            $query->where('id', '<', $request->last_item_id);
        }
        $items = $query->get();

        return GlobalFunction::sendDataResponse(true, 'Diamond transactions fetched successfully', $items);
    }

    public function fetchStarTransactions(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $rules = [
            'limit' => 'required|integer|min:1|max:100',
            'last_item_id' => 'nullable|integer|min:0',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $hasNotificationSourceColumn = Schema::hasColumn('notification_users', 'source');

        $giftCredits = DB::table('notification_users as n')
            ->join('tbl_gifts as g', 'g.id', '=', 'n.data_id')
            ->leftJoin('tbl_users as u', 'u.id', '=', 'n.from_user_id')
            ->where('n.type', Constants::notify_gift_user)
            ->where('n.to_user_id', $user->id)
            ->select(
                'n.id',
                'n.created_at',
                $hasNotificationSourceColumn ? 'n.source' : DB::raw("'chat_gift' as source"),
                'g.coin_price as stars',
                'u.id as from_user_id',
                'u.username as from_username',
                'u.fullname as from_fullname'
            )
            ->get()
            ->map(function ($item) {
                $senderName = trim((string) ($item->from_fullname ?: $item->from_username ?: 'Unknown'));
                return [
                    'sort_time' => Carbon::parse($item->created_at)->timestamp,
                    'sort_id' => intval($item->id),
                    'type' => 'credit',
                    'source' => !empty($item->source) ? strtolower(trim((string) $item->source)) : 'chat_gift',
                    'stars' => intval($item->stars),
                    'title' => 'Gift Received',
                    'description' => 'Received ' . intval($item->stars) . ' stars from ' . $senderName,
                    'reference_id' => intval($item->id),
                    'from_user_id' => !is_null($item->from_user_id) ? intval($item->from_user_id) : null,
                    'created_at' => Carbon::parse($item->created_at)->format('Y-m-d H:i:s'),
                ];
            });

        $payoutDebits = DB::table('tbl_manual_payouts')
            ->where('user_id', $user->id)
            ->select('id', 'coins', 'created_at', 'payout_date', 'note')
            ->get()
            ->map(function ($item) {
                $date = !empty($item->payout_date) ? $item->payout_date : $item->created_at;
                return [
                    'sort_time' => Carbon::parse($date)->timestamp,
                    'sort_id' => intval($item->id),
                    'type' => 'debit',
                    'source' => 'manual_payout',
                    'stars' => intval($item->coins),
                    'title' => 'Payout Deducted',
                    'description' => !empty($item->note) ? (string) $item->note : ('Payout processed for ' . intval($item->coins) . ' stars'),
                    'reference_id' => intval($item->id),
                    'from_user_id' => null,
                    'created_at' => Carbon::parse($date)->format('Y-m-d H:i:s'),
                ];
            });

        $allItems = $giftCredits
            ->concat($payoutDebits)
            ->sort(function ($a, $b) {
                if ($a['sort_time'] === $b['sort_time']) {
                    return $b['sort_id'] <=> $a['sort_id'];
                }
                return $b['sort_time'] <=> $a['sort_time'];
            })
            ->values()
            ->map(function ($item, $index) {
                $item['id'] = $index + 1;
                unset($item['sort_time'], $item['sort_id']);
                return $item;
            });

        $offset = intval($request->last_item_id ?? 0);
        $limit = intval($request->limit);
        $items = $allItems->slice($offset, $limit)->values();
        $nextOffset = $offset + $items->count();

        $groupedTransactions = [
            'chat_gift' => [],
            'audio_gift' => [],
            'video_gift' => [],
            'other' => [],
        ];

        foreach ($items as $item) {
            $source = strtolower((string) ($item['source'] ?? ''));
            $groupKey = 'other';

            if (in_array($source, ['chat_gift', 'audio_gift', 'video_gift'], true)) {
                $groupKey = $source;
            }

            $groupedTransactions[$groupKey][] = $item;
        }

        $groupTotals = [];
        foreach ($groupedTransactions as $key => $rows) {
            $groupTotals[$key] = intval(collect($rows)->sum(function ($row) {
                return intval($row['stars'] ?? 0);
            }));
        }

        return GlobalFunction::sendDataResponse(true, 'Star transactions fetched successfully', [
            'star_wallet' => intval($user->coin_wallet ?? 0),
            'star_collected_lifetime' => intval($user->coin_collected_lifetime ?? 0),
            'star_gifted_lifetime' => intval($user->coin_gifted_lifetime ?? 0),
            'transactions' => $items,
            'grouped_transactions' => $groupedTransactions,
            'group_totals' => $groupTotals,
            'next_last_item_id' => $nextOffset < $allItems->count() ? $nextOffset : null,
            'has_more' => $nextOffset < $allItems->count(),
        ]);
    }

    public function fetchDiamondTransactions(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $rules = [
            'limit' => 'required|integer|min:1|max:100',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $query = DiamondTransactions::where('user_id', $user->id)
            ->where('source', 'purchase')
            ->orderBy('id', 'DESC')
            ->limit($request->limit);
        if ($request->has('last_item_id')) {
            $query->where('id', '<', $request->last_item_id);
        }

        $items = $query->get([
            'id',
            'user_id',
            'payment_id',
            'diamond_pack_id',
            'diamonds',
            'amount',
            'status',
            'created_at',
        ]);

        return GlobalFunction::sendDataResponse(true, 'Transactions fetched', $items);
    }

    public function verifyDiamondPurchase(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $rules = [
            'payment_id' => 'required|string',
            'order_id' => 'nullable|string',
            'orderId' => 'nullable|string',
            'signature' => 'nullable|string',
            'diamond_pack_id' => 'required|exists:tbl_diamond_plan,id',
            'amount' => 'required|numeric|min:0',
            'coupon_code' => 'nullable|string|max:100',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $existing = DiamondTransactions::where('payment_id', $request->payment_id)
            ->where('status', 'success')
            ->first();
        if ($existing) {
            $fullUser = GlobalFunction::prepareUserFullData($user->id);
            return GlobalFunction::sendDataResponse(true, 'Diamonds credited successfully', $fullUser);
        }

        $package = DiamondPackages::find($request->diamond_pack_id);
        if (!$package || intval($package->status) !== 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Diamond package not found or inactive');
        }

        $expectedAmount = !is_null($package->discounted_price) ? floatval($package->discounted_price) : floatval($package->diamond_plan_price);
        $providedAmount = floatval($request->amount);

        $orderId = trim((string) ($request->order_id ?? $request->orderId ?? ''));
        $orderId = $orderId !== '' ? $orderId : null;

        if (!empty($orderId) && $request->filled('signature')) {
            $razorpaySecret = env('RAZORPAY_KEY_SECRET');
            if (!empty($razorpaySecret)) {
                $payload = $orderId . '|' . $request->payment_id;
                $generatedSignature = hash_hmac('sha256', $payload, $razorpaySecret);
                if (!hash_equals($generatedSignature, $request->signature)) {
                    return GlobalFunction::sendSimpleResponse(false, 'Invalid Razorpay signature');
                }
            }
        }

        $couponCode = strtoupper(trim((string) ($request->coupon_code ?? '')));
        $coupon = null;
        $discountAmount = 0.0;
        $finalPayableAmount = round($expectedAmount, 2);

        if ($couponCode !== '') {
            $today = Carbon::today()->toDateString();
            $coupon = Coupons::whereRaw('UPPER(coupon_code) = ?', [$couponCode])->first();
            if (!$coupon) {
                return GlobalFunction::sendSimpleResponse(false, 'Invalid coupon code');
            }

            if (intval($coupon->status) !== 1) {
                return GlobalFunction::sendSimpleResponse(false, 'Coupon is inactive');
            }

            if (!empty($coupon->end_date) && $coupon->end_date < $today) {
                return GlobalFunction::sendSimpleResponse(false, 'Coupon has expired');
            }

            $maxUsers = is_null($coupon->max_users) ? null : intval($coupon->max_users);
            $usedUsers = intval($coupon->used_users ?? 0);
            if (!is_null($maxUsers) && $usedUsers >= $maxUsers) {
                return GlobalFunction::sendSimpleResponse(false, 'Coupon usage limit exceeded');
            }

            if ($coupon->discount_type === 'percentage') {
                $discountAmount = ($expectedAmount * floatval($coupon->discount_value)) / 100;
            } else {
                $discountAmount = floatval($coupon->discount_value);
            }

            $discountAmount = max(0, min($discountAmount, $expectedAmount));
            $finalPayableAmount = round(max(0, $expectedAmount - $discountAmount), 2);
        }

        if (round($finalPayableAmount, 2) !== round($providedAmount, 2)) {
            return GlobalFunction::sendSimpleResponse(false, 'Amount mismatch for selected package');
        }

        $diamonds = intval($package->diamond_amount);
        $user->diamond_wallet = intval($user->diamond_wallet ?? 0) + $diamonds;
        $user->diamond_collected_lifetime = intval($user->diamond_collected_lifetime ?? 0) + $diamonds;
        $user->diamond_purchased_lifetime = intval($user->diamond_purchased_lifetime ?? 0) + $diamonds;
        $user->save();

        if ($coupon) {
            $coupon->used_users = intval($coupon->used_users ?? 0) + 1;
            $coupon->save();
        }

        $purchaseTransaction = $this->createDiamondTransaction(
            $user,
            Constants::credit,
            $diamonds,
            'purchase',
            'diamond_pack',
            $package->id,
            $coupon ? 'Razorpay purchase with coupon ' . $couponCode : 'Razorpay purchase',
            [
                'payment_id' => $request->payment_id,
                'order_id' => $orderId,
                'signature' => $request->signature,
                'diamond_pack_id' => $package->id,
                'amount' => round($providedAmount, 2),
                'status' => 'success',
            ]
        );

        $fullUser = GlobalFunction::prepareUserFullData($user->id);
        return GlobalFunction::sendDataResponse(true, 'Diamonds credited successfully', $fullUser);
    }

    public function fetchMyDiamondSpendHistory(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $rules = [
            'limit' => 'required|integer|min:1|max:100',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $query = DiamondSpendHistory::where('user_id', $user->id)->orderBy('id', 'DESC')->limit($request->limit);
        if ($request->has('last_item_id')) {
            $query->where('id', '<', $request->last_item_id);
        }
        $items = $query->get();

        return GlobalFunction::sendDataResponse(true, 'Diamond spend history fetched successfully', $items);
    }

    public function spendDiamonds(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $purpose = strtolower(trim((string) ($request->purpose ?? '')));
        if ($purpose === 'gift' && $request->filled('user_id') && $request->filled('gift_id')) {
            Log::info('spendDiamonds delegated to sendGift', [
                'from_user_id' => intval($user->id),
                'to_user_id' => intval($request->input('user_id')),
                'gift_id' => intval($request->input('gift_id')),
                'diamonds' => intval($request->input('diamonds')),
            ]);

            if (!$request->filled('source')) {
                $request->merge(['source' => 'chat_gift']);
            }

            return $this->sendGift($request);
        }

        $rules = [
            'diamonds' => 'required|integer|min:1',
            'purpose' => 'required|string|max:255',
            'reference_type' => 'nullable|string|max:100',
            'reference_id' => 'nullable|integer',
            'note' => 'nullable|string|max:1000',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $diamonds = intval($request->diamonds);
        if (($user->diamond_wallet ?? 0) < $diamonds) {
            return GlobalFunction::sendSimpleResponse(false, 'insufficient diamonds in wallet');
        }

        $user->diamond_wallet -= $diamonds;
        $user->diamond_spent_lifetime = intval($user->diamond_spent_lifetime ?? 0) + $diamonds;
        $user->save();

        $transaction = $this->createDiamondTransaction(
            $user,
            Constants::debit,
            $diamonds,
            'user_spend',
            $request->reference_type,
            $request->reference_id,
            $request->note
        );

        $spend = new DiamondSpendHistory();
        $spend->user_id = $user->id;
        $spend->diamonds = $diamonds;
        $spend->purpose = $request->purpose;
        $spend->reference_type = $request->reference_type;
        $spend->reference_id = $request->reference_id;
        $spend->transaction_id = $transaction->id;
        $spend->note = $request->note;
        $spend->save();

        return GlobalFunction::sendDataResponse(true, 'Diamonds spent successfully', [
            'diamond_wallet' => intval($user->diamond_wallet),
            'transaction' => $transaction,
            'spend' => $spend,
        ]);
    }

    public function buyCoins(Request $request){
        return GlobalFunction::sendSimpleResponse(false, 'Coin purchase is disabled. Please purchase diamonds only.');

        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'coin_package_id' => 'required|exists:tbl_coin_plan,id',
            'purchased_at' => 'required',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $date = Carbon::now();
        $timeInMilliseconds = $date->valueOf();
        $bufferTimeInMs = 30000;

        if($timeInMilliseconds - $request->purchased_at > $bufferTimeInMs){
            return GlobalFunction::sendSimpleResponse(false, 'something went wrong!-0');
        }

        $coinPackage = CoinPackages::find($request->coin_package_id);

        $userId = $user->id;
        $rcProjectId = env('RC_PROJECT_ID');
        $rcApiKey = env('RC_KIT_API_KEY');

         // Define the external API URL you want to call
         $apiUrl = 'https://api.revenuecat.com/v2/projects/'.$rcProjectId.'/customers/'.$userId.'/purchases?limit=10000';
        //  Log::debug($apiUrl);

         try {
             $response = Http::withHeaders([
                'Authorization' => 'Bearer ' . $rcApiKey
            ])->get($apiUrl);

             // Check if the request was successful
             if ($response->successful()) {

                // Log::debug($response->json());

                $jsonResponse = $response->json();
                $items = $jsonResponse['items'];
                // Log::debug($items);

              $matchedItem = collect($items)
                            ->filter(function ($item) {
                                return isset($item['store_purchase_identifier'], $item['purchased_at']);
                            })
                            ->sortByDesc('purchased_at')
                            ->first();


                if ($matchedItem) {

                    $date = Carbon::now();
                    $timeInMilliseconds = $date->valueOf();
                    if(($timeInMilliseconds - $matchedItem['purchased_at']) > $bufferTimeInMs){
                        return GlobalFunction::sendSimpleResponse(false, 'something went wrong!-1');
                    }

                    $productVerifyUrl = 'https://api.revenuecat.com/v2/projects/'.$rcProjectId.'/products/'.$matchedItem['product_id'];
                    $productResponse = Http::withHeaders([
                        'Authorization' => 'Bearer ' . $rcApiKey
                    ])->get($productVerifyUrl);

                    // Log::debug($matchedItem['product_id']);
                    // Log::debug($productResponse);

                    if ($productResponse->successful()) {
                         $productResponse = $productResponse->json();
                        //  Log::debug($productResponse);
                         if($matchedItem['store'] == 'play_store'){
                            $productId = $coinPackage->playstore_product_id;
                        }else{
                             $productId = $coinPackage->appstore_product_id;
                         }

                         if($productResponse['store_identifier'] != $productId){
                            return GlobalFunction::sendSimpleResponse(false,'somehting went wrong!-2');
                         }

                        $user->coin_wallet += $coinPackage->coin_amount;
                        $user->coin_purchased_lifetime += $coinPackage->coin_amount;
                        $user->save();

                        $user = GlobalFunction::prepareUserFullData($user->id);
                        return GlobalFunction::sendDataResponse(true, 'coins purchased successfully', $user);

                    }else{
                         return GlobalFunction::sendSimpleResponse(false,'somehting went wrong!-3');
                    }

                } else {
                    return GlobalFunction::sendSimpleResponse(false, 'no purchased item found!');
                }

            } else {
                // Log::debug($response->body());
               return GlobalFunction::sendSimpleResponse(false, 'something went wrong!-4');
             }
         } catch (\Exception $e) {
            //  Log::debug( $e->getMessage());
             return GlobalFunction::sendSimpleResponse(false, 'something went wrong!-5');

         }

    }

    public function addCoinsToUserWallet_FromAdmin(Request $request){
        $user = Users::find($request->user_id);
        $user->coin_wallet += $request->coins;
        $user->coin_collected_lifetime += $request->coins;
        $user->save();

         return GlobalFunction::sendSimpleResponse(true, 'Stars added to user wallet successfully!');
    }

    public function addDiamondsToUserWallet_FromAdmin(Request $request)
    {
        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
            'diamonds' => 'required|integer|min:1',
            'note' => 'nullable|string|max:1000',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $user = Users::find($request->user_id);
        $diamonds = intval($request->diamonds);
        $user->diamond_wallet = intval($user->diamond_wallet ?? 0) + $diamonds;
        $user->diamond_collected_lifetime = intval($user->diamond_collected_lifetime ?? 0) + $diamonds;
        $user->save();

        $transaction = $this->createDiamondTransaction(
            $user,
            Constants::credit,
            $diamonds,
            'admin_add',
            'admin',
            null,
            $request->note
        );

        return GlobalFunction::sendDataResponse(true, 'Diamonds added to user wallet successfully!', [
            'diamond_wallet' => intval($user->diamond_wallet),
            'transaction' => $transaction,
        ]);
    }

    public function listCoinPackages(Request $request)
    {
        $query = CoinPackages::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('coin_amount', 'LIKE', "%{$searchValue}%")
                ->orwhere('coin_plan_price', 'LIKE', "%{$searchValue}%")
                ->orwhere('playstore_product_id', 'LIKE', "%{$searchValue}%")
                ->orwhere('appstore_product_id', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $settings = GlobalSettings::first();
        $data = $result->map(function ($item) use($settings) {

            $imgUrl = GlobalFunction::generateFileUrl($item->image);
            $image = "<img class='rounded' width='80' height='80' src='{$imgUrl}' alt=''>";

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-coinamount='{$item->coin_amount}'
                        data-coinprice='{$item->coin_plan_price}'
                        data-playstoreid='{$item->playstore_product_id}'
                        data-appstoreid='{$item->appstore_product_id}'
                        data-image='{$imgUrl}'
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
            $status = "<input type='checkbox' id='coinPackageStatus-{$item->id}' rel='{$item->id}' class='onOffCoinPackage' {$checked} data-switch='none'/>
                    <label for='coinPackageStatus-{$item->id}'></label>";

            return [
                $image,
                $item->coin_amount,
                $settings->currency.$item->coin_plan_price,
                $status,
                $item->playstore_product_id,
                $item->appstore_product_id,
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

    function changeCoinPackageStatus(Request $request){
        $coinPackage = CoinPackages::find($request->id);
        $coinPackage->status = $request->status;
        $coinPackage->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }

    function editCoinPackage(Request $request){
        $item = CoinPackages::find($request->id);
        if($request->has('image')){
            if($item->image != null){
                GlobalFunction::deleteFile($item->image);
            }
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        $item->coin_amount = $request->coin_amount;
        $item->coin_plan_price = $request->coin_plan_price;
        $item->appstore_product_id = $request->appstore_product_id;
        $item->playstore_product_id = $request->playstore_product_id;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Star package edited successfully');
    }
    function addCoinPackage(Request $request){
        $item = new CoinPackages();
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->coin_amount = $request->coin_amount;
        $item->coin_plan_price = $request->coin_plan_price;
        $item->appstore_product_id = $request->appstore_product_id;
        $item->playstore_product_id = $request->playstore_product_id;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Star package added successfully');
    }
    function deleteCoinPackage(Request $request){
        $item = CoinPackages::find($request->id);
        GlobalFunction::deleteFile($item->image);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Star package deleted successfully');
    }

    public function coinPackages(){
        return view('coinPackages');
    }
    public function listDiamondPackages(Request $request)
    {
        $query = DiamondPackages::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('diamond_amount', 'LIKE', "%{$searchValue}%")
                ->orwhere('diamond_plan_price', 'LIKE', "%{$searchValue}%")
                ->orwhere('discounted_price', 'LIKE', "%{$searchValue}%")
                ->orwhere('playstore_product_id', 'LIKE', "%{$searchValue}%")
                ->orwhere('appstore_product_id', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $settings = GlobalSettings::first();
        $data = $result->map(function ($item) use ($settings) {
            $imgUrl = GlobalFunction::generateFileUrl($item->image);
            $image = "<img class='rounded' width='80' height='80' src='{$imgUrl}' alt=''>";

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-diamondamount='{$item->diamond_amount}'
                        data-diamondprice='{$item->diamond_plan_price}'
                        data-discountedprice='{$item->discounted_price}'
                        data-offerentryeffectid='{$item->offer_entry_effect_id}'
                        data-playstoreid='{$item->playstore_product_id}'
                        data-appstoreid='{$item->appstore_product_id}'
                        data-image='{$imgUrl}'
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
            $status = "<input type='checkbox' id='diamondPackageStatus-{$item->id}' rel='{$item->id}' class='onOffDiamondPackage' {$checked} data-switch='none'/>
                    <label for='diamondPackageStatus-{$item->id}'></label>";

            return [
                $image,
                $item->diamond_amount,
                $settings->currency.$item->diamond_plan_price,
                !is_null($item->discounted_price) ? $settings->currency.$item->discounted_price : '-',
                !is_null($item->offer_entry_effect_id) ? ('#'.$item->offer_entry_effect_id) : '-',
                $status,
                $item->playstore_product_id,
                $item->appstore_product_id,
                $action,
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

    function changeDiamondPackageStatus(Request $request){
        $diamondPackage = DiamondPackages::find($request->id);
        $diamondPackage->status = $request->status;
        $diamondPackage->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }

    function editDiamondPackage(Request $request){
        $item = DiamondPackages::find($request->id);
        if($request->has('image')){
            if($item->image != null){
                GlobalFunction::deleteFile($item->image);
            }
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        $item->diamond_amount = $request->diamond_amount;
        $item->diamond_plan_price = $request->diamond_plan_price;
        $item->discounted_price = $request->filled('discounted_price') ? $request->discounted_price : null;
        $item->offer_entry_effect_id = $request->filled('offer_entry_effect_id') ? $request->offer_entry_effect_id : null;
        $item->appstore_product_id = $request->appstore_product_id;
        $item->playstore_product_id = $request->playstore_product_id;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Diamond package edited successfully');
    }

    function addDiamondPackage(Request $request){
        $item = new DiamondPackages();
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->diamond_amount = $request->diamond_amount;
        $item->diamond_plan_price = $request->diamond_plan_price;
        $item->discounted_price = $request->filled('discounted_price') ? $request->discounted_price : null;
        $item->offer_entry_effect_id = $request->filled('offer_entry_effect_id') ? $request->offer_entry_effect_id : null;
        $item->appstore_product_id = $request->appstore_product_id;
        $item->playstore_product_id = $request->playstore_product_id;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Diamond package added successfully');
    }

    function deleteDiamondPackage(Request $request){
        $item = DiamondPackages::find($request->id);
        GlobalFunction::deleteFile($item->image);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Diamond package deleted successfully');
    }

    public function diamondPackages(){
        $entryEffects = EntryEffects::orderBy('id', 'DESC')->get(['id', 'title', 'coin_price', 'duration']);
        return view('diamondPackages', compact('entryEffects'));
    }

    public function diamondTransactions()
    {
        return view('diamondTransactions');
    }

    public function agentCommissionTransactions()
    {
        return view('agentCommissionTransactions');
    }

    public function hostAgentRequests()
    {
        return view('hostAgentRequests');
    }

    private function listRoleRequestsByStatus(Request $request, int $status)
    {
        $query = UserRoleRequests::where('status', $status);
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $requestType = null;
            if (stripos($searchValue, 'host') !== false) {
                $requestType = Constants::roleRequestHost;
            } elseif (stripos($searchValue, 'agent') !== false) {
                $requestType = Constants::roleRequestAgent;
            }

            $query->where(function ($q) use ($searchValue, $requestType) {
                $q->where('id', 'LIKE', "%{$searchValue}%");
                if (!is_null($requestType)) {
                    $q->orWhere('request_type', $requestType);
                }
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $data = $result->map(function ($item) use ($status) {
            $user = GlobalFunction::createUserDetailsColumn($item->user_id);
            $requestType = intval($item->request_type) === Constants::roleRequestHost
                ? "<span class='badge bg-primary'>HOST</span>"
                : "<span class='badge bg-info'>AGENT</span>";

            $statusBadge = "<span class='badge bg-warning'>PENDING</span>";
            if ($status === Constants::roleRequestAccepted) {
                $statusBadge = "<span class='badge bg-success'>ACCEPTED</span>";
            } elseif ($status === Constants::roleRequestRejected) {
                $statusBadge = "<span class='badge bg-danger'>REJECTED</span>";
            }

            if ($status === Constants::roleRequestPending) {
                $accept = "<a href='#'
                            rel='{$item->id}'
                            class='action-btn accept-role-request d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                            <i class='uil-check'></i>
                            </a>";

                $reject = "<a href='#'
                            rel='{$item->id}'
                            class='action-btn reject-role-request d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-times'></i>
                            </a>";
                $action = "<span class='d-flex justify-content-end align-items-center'>{$accept}{$reject}</span>";

                return [
                    "#{$item->id}",
                    $requestType,
                    $user,
                    GlobalFunction::formateDatabaseTime($item->requested_at ?? $item->created_at),
                    $statusBadge,
                    $action,
                ];
            }

            return [
                "#{$item->id}",
                $requestType,
                $user,
                GlobalFunction::formateDatabaseTime($item->requested_at ?? $item->created_at),
                GlobalFunction::formateDatabaseTime($item->action_at ?? $item->updated_at),
                $statusBadge,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function listPendingHostAgentRequests(Request $request)
    {
        return $this->listRoleRequestsByStatus($request, Constants::roleRequestPending);
    }

    public function listAcceptedHostAgentRequests(Request $request)
    {
        return $this->listRoleRequestsByStatus($request, Constants::roleRequestAccepted);
    }

    public function listRejectedHostAgentRequests(Request $request)
    {
        return $this->listRoleRequestsByStatus($request, Constants::roleRequestRejected);
    }

    public function acceptHostAgentRequest(Request $request)
    {
        $item = UserRoleRequests::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Request not found');
        }
        if (intval($item->status) !== Constants::roleRequestPending) {
            return GlobalFunction::sendSimpleResponse(false, 'Only pending requests can be accepted');
        }

        $item->status = Constants::roleRequestAccepted;
        $item->action_at = Carbon::now();
        $item->save();

        $user = Users::find($item->user_id);
        if ($user) {
            if (intval($item->request_type) === Constants::roleRequestHost) {
                $user->is_host = 1;
            } elseif (intval($item->request_type) === Constants::roleRequestAgent) {
                $user->is_agent = 1;
            }
            $user->save();
        }

        return GlobalFunction::sendSimpleResponse(true, 'Request accepted successfully');
    }

    public function rejectHostAgentRequest(Request $request)
    {
        $item = UserRoleRequests::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Request not found');
        }
        if (intval($item->status) !== Constants::roleRequestPending) {
            return GlobalFunction::sendSimpleResponse(false, 'Only pending requests can be rejected');
        }

        $item->status = Constants::roleRequestRejected;
        $item->action_at = Carbon::now();
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Request rejected successfully');
    }

    public function listDiamondTransactions(Request $request)
    {
        $query = DiamondTransactions::where('source', 'purchase');
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('payment_id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('order_id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('status', 'LIKE', "%{$searchValue}%")
                    ->orWhere('diamonds', 'LIKE', "%{$searchValue}%")
                    ->orWhere('amount', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $settings = GlobalSettings::first();

        $data = $result->map(function ($item) use ($settings) {
            $userItem = Users::find($item->user_id);
            $displayUsername = e($userItem->username ?? '-');
            $displayFullname = e($userItem->fullname ?? '-');
            $verifyIcon = intval($userItem->is_verify ?? 0) === 1
                ? "<img src='" . asset('assets/img/ic_verify.png') . "' alt='verified' class='ms-1 rounded-circle object-fit-cover custom-width-18px custom-height-18px'>"
                : '';
            $user = "<a href='" . route('viewUserDetails', $item->user_id) . "' class='text-decoration-none d-inline-block'><div class='text-dark fw-semibold'>{$displayUsername}{$verifyIcon}</div><div class='text-muted fs-6'>{$displayFullname}</div></a>";
            $pack = DiamondPackages::find($item->diamond_pack_id);
            $packDetails = $pack ? "<h5 class='m-0'>{$pack->diamond_amount} diamonds</h5><p class='m-0'>{$settings->currency}{$pack->diamond_plan_price}</p>" : '-';
            $amount = $item->amount !== null ? $settings->currency . number_format((float)$item->amount, 2) : '-';
            $displayOrderId = !empty($item->order_id) ? $item->order_id : $item->id;

            $statusBadge = $item->status == 'success'
                ? "<span class='badge bg-success'>SUCCESS</span>"
                : "<span class='badge bg-danger'>" . strtoupper($item->status ?? '-') . "</span>";

            return [
                $user,
                $item->payment_id ?? '-',
                $displayOrderId,
                $packDetails,
                $item->diamonds,
                $amount,
                $statusBadge,
                GlobalFunction::formateDatabaseTime($item->created_at),
            ];
        });

        $json_data = [
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ];

        return response()->json($json_data);
    }

    public function listAgentCommissionTransactions(Request $request)
    {
        $query = AgentCommissionEntries::query();
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('payment_id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('purchase_amount', 'LIKE', "%{$searchValue}%")
                    ->orWhere('commission_percent', 'LIKE', "%{$searchValue}%")
                    ->orWhere('commission_amount', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $items = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $settings = GlobalSettings::first();
        $currency = $settings->currency ?? '';

        $data = $items->map(function ($item) use ($currency) {
            $agent = GlobalFunction::createUserDetailsColumn($item->agent_id);
            $buyer = !empty($item->user_id) ? GlobalFunction::createUserDetailsColumn($item->user_id) : '-';
            $purchaseAmount = $currency . number_format((float) ($item->purchase_amount ?? 0), 2);
            $commissionPercent = number_format((float) ($item->commission_percent ?? 0), 2) . '%';
            $commissionAmount = $currency . number_format((float) ($item->commission_amount ?? 0), 2);

            return [
                "#{$item->id}",
                $agent,
                $buyer,
                $purchaseAmount,
                $commissionPercent,
                $commissionAmount,
                GlobalFunction::formateDatabaseTime($item->created_at),
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function rejectWithdrawal(Request $request){
        $item = RedeemRequests::find($request->id);
        $item->status = Constants::withdrawalRejected;
        $item->save();

        $user = $item->user;
        $user->coin_wallet += $item->coins;
        $user->save();

        return GlobalFunction::sendSimpleResponse(true,'withdrawal rejected successfully');
    }
    public function completeWithdrawal(Request $request){
        $item = RedeemRequests::find($request->id);
        $item->status = Constants::withdrawalCompleted;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true,'withdrawal complete successfully');
    }
    public function deleteGift(Request $request){
        $item = Gifts::find($request->id);
        GlobalFunction::deleteFile($item->image);
        if (!empty($item->animation_url)) {
            GlobalFunction::deleteFile($item->animation_url);
        }
        if (!empty($item->sound_url)) {
            GlobalFunction::deleteFile($item->sound_url);
        }
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'gift deleted successfully');
    }
    public function listCompletedWithdrawals(Request $request)
    {
        $query = RedeemRequests::where('status', Constants::withdrawalCompleted);
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('request_number', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $settings = GlobalSettings::first();
        $data = $result->map(function ($item) use($settings) {

            $user = GlobalFunction::createUserDetailsColumn($item->user_id);

            $amount = "<h4 class='text-primary m-0'>{$settings->currency} {$item->amount}</h4>";
            $withdrawal = $amount."<span class='fs-6'>Stars: {$item->coins}</span><br><span class='fs-6'>Star Value: {$item->coin_value}</span>";

            $gateway = "<span class='badge badge-info-lighten fs-6'>{$item->gateway}</span>";
            $paymentDetails = $gateway."<br><span class='fs-6'>{$item->account}</span>";

            $requestNumber = "<h5 class='text-success'>#{$item->request_number}</h5>";


            return [
                $requestNumber,
                $user,
                $withdrawal,
                $paymentDetails,
                GlobalFunction::formateDatabaseTime($item->created_at),
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
    public function listRejectedWithdrawals(Request $request)
    {
        $query = RedeemRequests::where('status', Constants::withdrawalRejected);
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('request_number', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $settings = GlobalSettings::first();
        $data = $result->map(function ($item) use($settings) {

            $user = GlobalFunction::createUserDetailsColumn($item->user_id);

            $amount = "<h4 class='text-primary m-0'>{$settings->currency} {$item->amount}</h4>";
            $withdrawal = $amount."<span class='fs-6'>Stars: {$item->coins}</span><br><span class='fs-6'>Star Value: {$item->coin_value}</span>";

            $gateway = "<span class='badge badge-info-lighten fs-6'>{$item->gateway}</span>";
            $paymentDetails = $gateway."<br><span class='fs-6'>{$item->account}</span>";

            $requestNumber = "<h5 class='text-danger'>#{$item->request_number}</h5>";


            return [
                $requestNumber,
                $user,
                $withdrawal,
                $paymentDetails,
                GlobalFunction::formateDatabaseTime($item->created_at),
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
    public function listPendingWithdrawals(Request $request)
    {
        $query = RedeemRequests::where('status', Constants::withdrawalPending);
        $totalData = $query->count();

        $columns = ['id'];
        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('request_number', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $settings = GlobalSettings::first();
        $data = $result->map(function ($item) use($settings) {

            $user = GlobalFunction::createUserDetailsColumn($item->user_id);

            $amount = "<h4 class='text-primary m-0'>{$settings->currency} {$item->amount}</h4>";
            $withdrawal = $amount."<span class='fs-6'>Stars: {$item->coins}</span><br><span class='fs-6'>Star Value: {$item->coin_value}</span>";

            $gateway = "<span class='badge badge-info-lighten fs-6'>{$item->gateway}</span>";
            $paymentDetails = $gateway."<br><span class='fs-6'>{$item->account}</span>";

            $requestNumber = "<h5 class='text-primary'>#{$item->request_number}</h5>";

            $complete = "<a href='#'
                        rel='{$item->id}'
                        class='action-btn complete d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-check'></i>
                        </a>";

            $reject = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn reject d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-times'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$complete}{$reject}</span>";

            return [
                $requestNumber,
                $user,
                $withdrawal,
                $paymentDetails,
                GlobalFunction::formateDatabaseTime($item->created_at),
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
    public function withdrawals(){
        return view('withdrawals');
    }

    public function manualPayouts()
    {
        return view('manualPayouts');
    }
    public function gifts(){
        $gifts = Gifts::with('category')->get();
        $giftCategories = GiftCategory::orderBy('name')->get(['id', 'name']);
        $baseUrl = GlobalFunction::getItemBaseUrl();
        return view('gifts' ,compact('gifts','baseUrl', 'giftCategories'));
    }

    public function giftDetails()
    {
        return view('giftDetails');
    }

    public function giftCategories()
    {
        $categories = GiftCategory::orderBy('id', 'DESC')->get();
        $baseUrl = GlobalFunction::getItemBaseUrl();
        return view('giftCategories', compact('categories', 'baseUrl'));
    }

    public function banners()
    {
        $items = Banner::orderBy('id', 'DESC')->get();
        $baseUrl = GlobalFunction::getItemBaseUrl();
        return view('banners', compact('items', 'baseUrl'));
    }

    public function entryEffects(){
        $entryEffects = EntryEffects::all();
        $baseUrl = GlobalFunction::getItemBaseUrl();
        return view('entryEffects' ,compact('entryEffects','baseUrl'));
    }

    public function diamondBuyingInformation()
    {
        $items = DiamondBuyingInformation::orderBy('id', 'ASC')->get();
        return view('diamondBuyingInformation', compact('items'));
    }

    public function packageDetails()
    {
        return view('packageDetails');
    }

    public function diamondFaqs()
    {
        $items = DiamondFaq::orderBy('id', 'ASC')->get();
        return view('diamondFaqs', compact('items'));
    }

    private function validateGiftImage(Request $request, bool $required = true)
    {
        if (!$request->hasFile('image')) {
            return $required ? 'Gift image is required' : null;
        }
        $file = $request->file('image');
        if (!$file->isValid()) {
            return 'Invalid image file uploaded';
        }
        $ext = strtolower($file->getClientOriginalExtension());
        $allowed = ['jpg', 'jpeg', 'png', 'gif', 'svg', 'webp'];
        if (!in_array($ext, $allowed)) {
            return 'Image must be a valid file (' . implode(', ', $allowed) . ')';
        }
        return null;
    }

    private function validateGiftAnimation(Request $request)
    {
        if (!$request->hasFile('animation')) {
            return null;
        }
        $file = $request->file('animation');
        if (!$file->isValid()) {
            return 'Invalid animation file uploaded';
        }
        $ext = strtolower($file->getClientOriginalExtension());
        $allowed = ['svga', 'svg', 'gif', 'png', 'webp'];
        if (!in_array($ext, $allowed)) {
            return 'Animation file must be an .svga, .svg, or .gif file';
        }
        return null;
    }

    private function validateGiftSound(Request $request)
    {
        if (!$request->hasFile('sound')) {
            return null;
        }
        $file = $request->file('sound');
        if (!$file->isValid()) {
            return 'Invalid sound file uploaded';
        }
        $ext = strtolower($file->getClientOriginalExtension());
        $allowed = ['mp3', 'wav', 'm4a', 'aac', 'ogg', 'mp4'];
        if (!in_array($ext, $allowed)) {
            return 'Sound file must be audio (mp3, wav, m4a, aac, ogg, mp4)';
        }
        return null;
    }

    public function editGift(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:tbl_gifts,id',
            'title' => 'nullable|string|max:100',
            'coin_price' => 'required|integer|min:1',
            'gift_category_id' => 'required|exists:tbl_gift_categories,id',
            'animation' => 'nullable|file|max:20480',
            'sound' => 'nullable|file|max:20480',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ]);
        }
        if ($imageError = $this->validateGiftImage($request, false)) {
            return response()->json(['status' => false, 'message' => $imageError]);
        }
        if ($animationError = $this->validateGiftAnimation($request)) {
            return response()->json(['status' => false, 'message' => $animationError]);
        }
        if ($soundError = $this->validateGiftSound($request)) {
            return response()->json(['status' => false, 'message' => $soundError]);
        }

        $item = Gifts::find($request->id);
        $item->title = $request->filled('title') ? $request->title : $item->title;
        $item->coin_price = $request->coin_price;
        $item->diamond_price = $request->coin_price;
        $item->gift_category_id = intval($request->gift_category_id);
        if ($request->hasFile('image')) {
            GlobalFunction::deleteFile($item->image);
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        if ($request->hasFile('animation')) {
            if (!empty($item->animation_url)) {
                GlobalFunction::deleteFile($item->animation_url);
            }
            $item->animation_url = GlobalFunction::saveFileAndGivePath($request->animation);
        }
        if ($request->hasFile('sound')) {
            if (!empty($item->sound_url)) {
                GlobalFunction::deleteFile($item->sound_url);
            }
            $item->sound_url = GlobalFunction::saveFileAndGivePath($request->sound);
        }
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Gift Updated Successfully',
        ]);
    }

    public function addGift(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'nullable|string|max:100',
            'coin_price' => 'required|integer|min:1',
            'gift_category_id' => 'required|exists:tbl_gift_categories,id',
            'animation' => 'nullable|file|max:20480',
            'sound' => 'nullable|file|max:20480',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ]);
        }
        if ($imageError = $this->validateGiftImage($request, true)) {
            return response()->json(['status' => false, 'message' => $imageError]);
        }
        if ($animationError = $this->validateGiftAnimation($request)) {
            return response()->json(['status' => false, 'message' => $animationError]);
        }
        if ($soundError = $this->validateGiftSound($request)) {
            return response()->json(['status' => false, 'message' => $soundError]);
        }

        $item = new Gifts();
        $item->title = $request->title;
        $item->coin_price = $request->coin_price;
        $item->diamond_price = $request->coin_price;
        $item->gift_category_id = intval($request->gift_category_id);
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        if ($request->hasFile('animation')) {
            $item->animation_url = GlobalFunction::saveFileAndGivePath($request->animation);
        }
        if ($request->hasFile('sound')) {
            $item->sound_url = GlobalFunction::saveFileAndGivePath($request->sound);
        }
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Gift Added Successfully',
        ]);
    }

    public function addGiftCategory(Request $request)
    {
        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return response()->json([
                'status' => false,
                'message' => 'Name is required',
            ]);
        }

        if (!$request->has('image')) {
            return response()->json([
                'status' => false,
                'message' => 'Image is required',
            ]);
        }

        $item = new GiftCategory();
        $item->name = $name;
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Gift category added successfully',
        ]);
    }

    public function editGiftCategory(Request $request)
    {
        $item = GiftCategory::find($request->id);
        if (!$item) {
            return response()->json([
                'status' => false,
                'message' => 'Gift category not found',
            ]);
        }

        $name = trim((string) ($request->name ?? ''));
        if ($name === '') {
            return response()->json([
                'status' => false,
                'message' => 'Name is required',
            ]);
        }

        $item->name = $name;
        if ($request->has('image')) {
            if (!empty($item->image)) {
                GlobalFunction::deleteFile($item->image);
            }
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Gift category updated successfully',
        ]);
    }

    public function deleteGiftCategory(Request $request)
    {
        $item = GiftCategory::find($request->id);
        if (!$item) {
            return response()->json([
                'status' => false,
                'message' => 'Gift category not found',
            ]);
        }

        if (!empty($item->image)) {
            GlobalFunction::deleteFile($item->image);
        }
        $item->delete();

        return response()->json([
            'status' => true,
            'message' => 'Gift category deleted successfully',
        ]);
    }

    public function addBanner(Request $request)
    {
        if (!$request->has('image')) {
            return response()->json([
                'status' => false,
                'message' => 'Image is required',
            ]);
        }

        $type = strtolower(trim((string) ($request->type ?? '')));
        if (!in_array($type, ['audio', 'homepage'], true)) {
            return response()->json([
                'status' => false,
                'message' => 'Type must be audio or homepage',
            ]);
        }

        $item = new Banner();
        $item->type = $type;
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Banner added successfully',
        ]);
    }

    public function editBanner(Request $request)
    {
        $item = Banner::find($request->id);
        if (!$item) {
            return response()->json([
                'status' => false,
                'message' => 'Banner not found',
            ]);
        }

        $type = strtolower(trim((string) ($request->type ?? '')));
        if (!in_array($type, ['audio', 'homepage'], true)) {
            return response()->json([
                'status' => false,
                'message' => 'Type must be audio or homepage',
            ]);
        }

        $item->type = $type;
        if ($request->has('image')) {
            if (!empty($item->image)) {
                GlobalFunction::deleteFile($item->image);
            }
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Banner updated successfully',
        ]);
    }

    public function deleteBanner(Request $request)
    {
        $item = Banner::find($request->id);
        if (!$item) {
            return response()->json([
                'status' => false,
                'message' => 'Banner not found',
            ]);
        }

        if (!empty($item->image)) {
            GlobalFunction::deleteFile($item->image);
        }
        $item->delete();

        return response()->json([
            'status' => true,
            'message' => 'Banner deleted successfully',
        ]);
    }

    public function editEntryEffect(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:tbl_entry_effects,id',
            'title' => 'required|string',
            'coin_price' => 'required|integer|min:1',
            'duration' => 'required|integer|min:1',
            'image' => 'nullable|file',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ]);
        }

        if ($request->hasFile('image') && strtolower($request->file('image')->getClientOriginalExtension()) !== 'svga') {
            return response()->json([
                'status' => false,
                'message' => 'SVGA file is required',
            ]);
        }

        $item = EntryEffects::find($request->id);
        $item->title = trim((string) $request->title);
        $item->coin_price = intval($request->coin_price);
        $item->duration = intval($request->duration);
        if($request->hasFile('image')){
            GlobalFunction::deleteFile($item->image);
            $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        }
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Entry Effect Updated Successfully',
        ]);
    }

    public function addEntryEffect(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'title' => 'required|string',
            'coin_price' => 'required|integer|min:1',
            'duration' => 'required|integer|min:1',
            'image' => 'required|file',
        ]);
        if ($validator->fails()) {
            return response()->json([
                'status' => false,
                'message' => $validator->errors()->first(),
            ]);
        }

        if (strtolower($request->file('image')->getClientOriginalExtension()) !== 'svga') {
            return response()->json([
                'status' => false,
                'message' => 'SVGA file is required',
            ]);
        }

        $item = new EntryEffects();
        $item->title = trim((string) $request->title);
        $item->coin_price = intval($request->coin_price);
        $item->duration = intval($request->duration);
        $item->image = GlobalFunction::saveFileAndGivePath($request->image);
        $item->save();

        return response()->json([
            'status' => true,
            'message' => 'Entry Effect Added Successfully',
        ]);
    }

    public function deleteEntryEffect(Request $request){
        $item = EntryEffects::find($request->id);
        GlobalFunction::deleteFile($item->image);
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Entry Effect deleted successfully');
    }

    public function addDiamondBuyingInformation(Request $request)
    {
        $information = trim((string) ($request->information ?? ''));
        if ($information === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Information is required');
        }

        $item = new DiamondBuyingInformation();
        $item->information = $information;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Information added successfully');
    }

    public function editDiamondBuyingInformation(Request $request)
    {
        $information = trim((string) ($request->information ?? ''));
        if ($information === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Information is required');
        }

        $item = DiamondBuyingInformation::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Information not found');
        }

        $item->information = $information;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Information updated successfully');
    }

    public function deleteDiamondBuyingInformation(Request $request)
    {
        $item = DiamondBuyingInformation::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Information not found');
        }

        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Information deleted successfully');
    }

    public function addDiamondFaq(Request $request)
    {
        $category = strtolower(trim((string) ($request->category ?? 'diamond')));
        $question = trim((string) ($request->question ?? ''));
        $answer = trim((string) ($request->answer ?? ''));
        if (!in_array($category, ['diamond', 'payment', 'withdrawal', 'gift', 'general'], true)) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid FAQ category');
        }
        if ($question === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Question is required');
        }
        if ($answer === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Answer is required');
        }

        $item = new DiamondFaq();
        $item->category = $category;
        $item->question = $question;
        $item->answer = $answer;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'FAQ added successfully');
    }

    public function editDiamondFaq(Request $request)
    {
        $category = strtolower(trim((string) ($request->category ?? 'diamond')));
        $question = trim((string) ($request->question ?? ''));
        $answer = trim((string) ($request->answer ?? ''));
        if (!in_array($category, ['diamond', 'payment', 'withdrawal', 'gift', 'general'], true)) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid FAQ category');
        }
        if ($question === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Question is required');
        }
        if ($answer === '') {
            return GlobalFunction::sendSimpleResponse(false, 'Answer is required');
        }

        $item = DiamondFaq::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'FAQ not found');
        }

        $item->category = $category;
        $item->question = $question;
        $item->answer = $answer;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'FAQ updated successfully');
    }

    public function deleteDiamondFaq(Request $request)
    {
        $item = DiamondFaq::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'FAQ not found');
        }

        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'FAQ deleted successfully');
    }

    public function fetchMyWithdrawalRequest(Request $request){
        return GlobalFunction::sendSimpleResponse(false, 'Withdrawal is disabled. Payout is handled manually by admin.');

        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'limit' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            $messages = $validator->errors()->all();
            $msg = $messages[0];
            return response()->json(['status' => false, 'message' => $msg]);
        }

        $query = RedeemRequests::where('user_id', $user->id)
        ->orderBy('id', 'DESC')
        ->limit($request->limit);
        if($request->has('last_item_id')){
            $query->where('id','<',$request->last_item_id);
        }

        $redeemRequests =  $query->get();

        return GlobalFunction::sendDataResponse(true, 'Withdrawal requests fetched successfully', $redeemRequests);

    }
    //
    public function submitWithdrawalRequest(Request $request){
        return GlobalFunction::sendSimpleResponse(false, 'Withdrawal is disabled. Payout is handled manually by admin.');

        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'coins' => 'required',
            'gateway' => 'required',
            'account' => 'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }
        $settings = GlobalSettings::first();
        if($request->coins < $settings->min_redeem_coins){
            return GlobalFunction::sendSimpleResponse(false, 'min. amount to Withdrawal is '. $settings->min_redeem_coins);
        }
        if($request->coins > $user->coin_wallet){
            return GlobalFunction::sendSimpleResponse(false, 'insufficient coins to redeem');
        }
        $redeem = new RedeemRequests();
        $redeem->request_number = GlobalFunction::generateRedeemRequestNumber($user->id);
        $redeem->user_id = $user->id;
        $redeem->gateway = $request->gateway;
        $redeem->account = $request->account;
        $redeem->coins = $request->coins;
        $redeem->coin_value = $settings->coin_value;
        $redeem->amount = $settings->coin_value * $request->coins;
        $redeem->save();

        $user->coin_wallet -= $request->coins;
        $user->save();

        return GlobalFunction::sendSimpleResponse(true, 'Withdrawal submitted successfully');

    }

    public function addManualPayout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:tbl_users,id',
            'transferred_amount' => 'required|numeric|min:0.01',
            'paid_date' => 'required|date',
            'transaction_id' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $user = Users::find($request->user_id);
        if (intval($user->is_dummy ?? 0) === 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Only real users are allowed for payout');
        }
        $settings = GlobalSettings::first();
        $coinValue = floatval($settings->coin_value ?? 0);
        if ($coinValue <= 0) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid star conversion value in settings');
        }

        $transferredAmount = round(floatval($request->transferred_amount), 2);
        if ($transferredAmount <= 0) {
            return GlobalFunction::sendSimpleResponse(false, 'Payout amount must be greater than zero');
        }

        $maxPayoutAmount = round(intval($user->coin_wallet ?? 0) * $coinValue, 2);
        if ($transferredAmount > $maxPayoutAmount) {
            return GlobalFunction::sendSimpleResponse(false, 'Payout amount exceeds max payout amount');
        }

        $rawCoins = $transferredAmount / $coinValue;
        $coins = intval(round($rawCoins));
        if ($coins < 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Payout amount is too low to convert into stars');
        }
        if (abs($rawCoins - $coins) > 0.000001) {
            return GlobalFunction::sendSimpleResponse(false, 'Payout amount must match star conversion exactly');
        }

        if (intval($user->coin_wallet ?? 0) < $coins) {
            return GlobalFunction::sendSimpleResponse(false, 'Insufficient stars in user wallet');
        }

        $user->coin_wallet = intval($user->coin_wallet ?? 0) - $coins;
        $user->save();

        $payout = new ManualPayout();
        $payout->user_id = intval($user->id);
        $payout->coins = $coins;
        $payout->amount = $transferredAmount;
        $payout->paid_amount = $transferredAmount;
        $payout->commission_percent = 0;
        $payout->commission_amount = 0;
        $payout->transaction_id = trim($request->transaction_id);
        $payout->period_type = 'manual_user';
        $payout->note = $request->description;
        $payout->payout_date = Carbon::parse($request->paid_date);
        $payout->save();

        return GlobalFunction::sendDataResponse(true, 'Manual payout marked successfully', [
            'remaining_stars' => intval($user->coin_wallet ?? 0),
            'deducted_stars' => $coins,
            'paid_amount' => $transferredAmount,
            'commission_percent' => 0,
            'commission_amount' => 0,
            'payout_amount' => $transferredAmount,
            'agent_commission_credited' => 0,
            'payout_id' => intval($payout->id),
        ]);
    }

    public function listTodayRealUsersPayout(Request $request)
    {
        $query = Users::where('is_dummy', 0);
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('username', 'LIKE', "%{$searchValue}%")
                    ->orWhere('fullname', 'LIKE', "%{$searchValue}%")
                    ->orWhere('user_email', 'LIKE', "%{$searchValue}%")
                    ->orWhere('coin_wallet', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $items = $query->offset($start)
            ->limit($limit)
            ->orderBy('coin_wallet', 'DESC')
            ->orderBy('id', 'DESC')
            ->get();

        $todayDate = Carbon::now()->format('Y-m-d');
        $settings = GlobalSettings::first();
        $coinValue = floatval($settings->coin_value ?? 0);
        $currency = $settings->currency ?? '';

        $data = $items->map(function ($item) use ($todayDate, $coinValue, $currency) {
            $user = GlobalFunction::createUserDetailsColumn($item->id);
            $availableStars = intval($item->coin_wallet ?? 0);
            $maxPayoutRaw = round($availableStars * $coinValue, 2);
            $paidAmount = $currency . number_format($maxPayoutRaw, 2);
            $action = "<a href='#'
                        class='action-btn use-for-payout d-flex align-items-center justify-content-center btn border rounded-2 text-primary ms-1'
                        data-user-id='{$item->id}'
                        data-stars='{$availableStars}'
                        data-max-amount='{$maxPayoutRaw}'>
                        <i class='uil-check-circle'></i>
                       </a>";

            return [
                $user,
                $availableStars,
                $paidAmount,
                $todayDate,
                "<span class='d-flex justify-content-end align-items-center'>{$action}</span>",
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function listManualPayouts(Request $request)
    {
        $query = ManualPayout::query()->where(function ($q) {
            $q->whereNull('period_type')
                ->orWhere('period_type', 'manual')
                ->orWhere('period_type', 'manual_user');
        });
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('coins', 'LIKE', "%{$searchValue}%")
                    ->orWhere('note', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $items = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $settings = GlobalSettings::first();
        $currency = $settings->currency ?? '';
        $data = $items->map(function ($item) use ($currency) {
            $user = GlobalFunction::createUserDetailsColumn($item->user_id);
            $paidAmountRaw = floatval($item->paid_amount ?? 0);
            if ($paidAmountRaw <= 0 && !is_null($item->amount)) {
                $paidAmountRaw = floatval($item->amount);
            }
            $paidAmount = $currency . number_format($paidAmountRaw, 2);

            return [
                "#{$item->id}",
                $user,
                intval($item->coins),
                $paidAmount,
                !empty($item->transaction_id) ? e($item->transaction_id) : '-',
                !empty($item->note) ? e($item->note) : '-',
                GlobalFunction::formateDatabaseTime($item->payout_date ?? $item->created_at),
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function addManualAgentPayout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'agent_id' => 'required|exists:tbl_users,id',
            'transferred_amount' => 'required|numeric|min:0.01',
            'paid_date' => 'required|date',
            'transaction_id' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $agent = Users::where('id', intval($request->agent_id))
            ->where('is_agent', 1)
            ->first();
        if (!$agent) {
            return GlobalFunction::sendSimpleResponse(false, 'Agent not found');
        }

        $transferredAmount = round(floatval($request->transferred_amount), 2);
        $maxAmount = round(floatval($agent->agent_commission_wallet ?? 0), 2);
        if ($transferredAmount > $maxAmount) {
            return GlobalFunction::sendSimpleResponse(false, 'Transferred amount exceeds available commission wallet');
        }

        $agent->agent_commission_wallet = round($maxAmount - $transferredAmount, 2);
        $agent->save();

        $payout = new ManualPayout();
        $payout->user_id = intval($agent->id);
        $payout->coins = 0;
        $payout->amount = $transferredAmount;
        $payout->paid_amount = $transferredAmount;
        $payout->commission_percent = 0;
        $payout->commission_amount = 0;
        $payout->transaction_id = trim($request->transaction_id);
        $payout->period_type = 'manual_agent';
        $payout->note = $request->description;
        $payout->payout_date = Carbon::parse($request->paid_date);
        $payout->save();

        return GlobalFunction::sendDataResponse(true, 'Agent payout marked successfully', [
            'remaining_commission_wallet' => round(floatval($agent->agent_commission_wallet ?? 0), 2),
            'paid_amount' => $transferredAmount,
            'payout_id' => intval($payout->id),
        ]);
    }

    public function listTodayAgentCommissionPayout(Request $request)
    {
        $query = Users::where('is_agent', 1)->where('is_dummy', 0);
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('username', 'LIKE', "%{$searchValue}%")
                    ->orWhere('fullname', 'LIKE', "%{$searchValue}%")
                    ->orWhere('user_email', 'LIKE', "%{$searchValue}%")
                    ->orWhere('agent_commission_wallet', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $items = $query->offset($start)
            ->limit($limit)
            ->orderBy('agent_commission_wallet', 'DESC')
            ->orderBy('id', 'DESC')
            ->get();

        $todayDate = Carbon::now()->format('Y-m-d');
        $settings = GlobalSettings::first();
        $currency = $settings->currency ?? '';

        $totalCommissionByAgent = AgentCommissionEntries::selectRaw('agent_id, SUM(commission_amount) as total_commission')
            ->groupBy('agent_id')
            ->pluck('total_commission', 'agent_id');

        $data = $items->map(function ($item) use ($todayDate, $currency, $totalCommissionByAgent) {
            $agent = GlobalFunction::createUserDetailsColumn($item->id);
            $availableWallet = round(floatval($item->agent_commission_wallet ?? 0), 2);
            $lifetimeCommission = round(floatval($totalCommissionByAgent[$item->id] ?? 0), 2);
            $walletLabel = $currency . number_format($availableWallet, 2);
            $lifetimeLabel = $currency . number_format($lifetimeCommission, 2);
            $amountLabel = $currency . number_format($availableWallet, 2);
            $action = "<a href='#'
                        class='action-btn use-for-agent-payout d-flex align-items-center justify-content-center btn border rounded-2 text-primary ms-1'
                        data-agent-id='{$item->id}'
                        data-wallet='{$availableWallet}'>
                        <i class='uil-check-circle'></i>
                       </a>";

            return [
                $agent,
                $walletLabel,
                $lifetimeLabel,
                $amountLabel,
                $todayDate,
                "<span class='d-flex justify-content-end align-items-center'>{$action}</span>",
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function listManualAgentPayouts(Request $request)
    {
        $query = ManualPayout::where('period_type', 'manual_agent');
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('amount', 'LIKE', "%{$searchValue}%")
                    ->orWhere('note', 'LIKE', "%{$searchValue}%")
                    ->orWhere('transaction_id', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $items = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $settings = GlobalSettings::first();
        $currency = $settings->currency ?? '';
        $data = $items->map(function ($item) use ($currency) {
            $agent = GlobalFunction::createUserDetailsColumn($item->user_id);
            $amount = $currency . number_format(floatval($item->amount ?? 0), 2);

            return [
                "#{$item->id}",
                $agent,
                $amount,
                !empty($item->transaction_id) ? e($item->transaction_id) : '-',
                !empty($item->note) ? e($item->note) : '-',
                GlobalFunction::formateDatabaseTime($item->payout_date ?? $item->created_at),
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function listTodayAdminPayout(Request $request)
    {
        $settings = GlobalSettings::first();
        $wallet = round(floatval($settings->admin_wallet ?? 0), 2);
        $currency = $settings->currency ?? '';
        $todayDate = Carbon::now()->format('Y-m-d');

        $data = [[
            'Admin Wallet',
            $currency . number_format($wallet, 2),
            $currency . number_format($wallet, 2),
            $todayDate,
            "<span class='d-flex justify-content-end align-items-center'><a href='#' class='action-btn use-for-admin-payout d-flex align-items-center justify-content-center btn border rounded-2 text-primary ms-1' data-wallet='{$wallet}'><i class='uil-check-circle'></i></a></span>",
        ]];

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => 1,
            'recordsFiltered' => 1,
            'data' => $data,
        ]);
    }

    public function addManualAdminPayout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'transferred_amount' => 'required|numeric|min:0.01',
            'paid_date' => 'required|date',
            'transaction_id' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $settings = GlobalSettings::first();
        $transferredAmount = round(floatval($request->transferred_amount), 2);
        $maxAmount = round(floatval($settings->admin_wallet ?? 0), 2);
        if ($transferredAmount > $maxAmount) {
            return GlobalFunction::sendSimpleResponse(false, 'Transferred amount exceeds admin wallet');
        }

        DB::transaction(function () use ($settings, $transferredAmount, $request) {
            $settings->admin_wallet = round(floatval($settings->admin_wallet ?? 0) - $transferredAmount, 2);
            $settings->save();

            $payout = new ManualPayout();
            $payout->user_id = 0;
            $payout->coins = 0;
            $payout->amount = $transferredAmount;
            $payout->paid_amount = $transferredAmount;
            $payout->commission_percent = 0;
            $payout->commission_amount = 0;
            $payout->transaction_id = trim($request->transaction_id);
            $payout->period_type = 'manual_admin';
            $payout->note = $request->description;
            $payout->payout_date = Carbon::parse($request->paid_date);
            $payout->save();
        });

        return GlobalFunction::sendSimpleResponse(true, 'Admin payout marked successfully');
    }

    public function listManualAdminPayouts(Request $request)
    {
        $query = ManualPayout::where('period_type', 'manual_admin');
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('amount', 'LIKE', "%{$searchValue}%")
                    ->orWhere('note', 'LIKE', "%{$searchValue}%")
                    ->orWhere('transaction_id', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();
        $items = $query->offset($start)->limit($limit)->orderBy('id', 'DESC')->get();
        $settings = GlobalSettings::first();
        $currency = $settings->currency ?? '';

        $data = $items->map(function ($item) use ($currency) {
            return [
                "#{$item->id}",
                'Admin Wallet',
                $currency . number_format(floatval($item->amount ?? 0), 2),
                !empty($item->transaction_id) ? e($item->transaction_id) : '-',
                !empty($item->note) ? e($item->note) : '-',
                GlobalFunction::formateDatabaseTime($item->payout_date ?? $item->created_at),
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function listTodayStateAgentPayout(Request $request)
    {
        $stateAgentIds = StateMaster::whereNotNull('agent_id')
            ->where('agent_id', '>', 0)
            ->distinct()
            ->pluck('agent_id');

        $query = Users::whereIn('id', $stateAgentIds)->where('is_dummy', 0);
        $totalData = $query->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');
        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('username', 'LIKE', "%{$searchValue}%")
                    ->orWhere('fullname', 'LIKE', "%{$searchValue}%")
                    ->orWhere('coin_wallet', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $items = $query->offset($start)->limit($limit)->orderBy('coin_wallet', 'DESC')->orderBy('id', 'DESC')->get();
        $todayDate = Carbon::now()->format('Y-m-d');
        $settings = GlobalSettings::first();
        $coinValue = floatval($settings->coin_value ?? 0);
        $currency = $settings->currency ?? '';

        $data = $items->map(function ($item) use ($todayDate, $coinValue, $currency) {
            $user = GlobalFunction::createUserDetailsColumn($item->id);
            $availableStars = intval($item->coin_wallet ?? 0);
            $maxAmount = round($availableStars * $coinValue, 2);
            $action = "<a href='#' class='action-btn use-for-state-agent-payout d-flex align-items-center justify-content-center btn border rounded-2 text-primary ms-1' data-user-id='{$item->id}' data-stars='{$availableStars}' data-max-amount='{$maxAmount}'><i class='uil-check-circle'></i></a>";
            return [
                $user,
                $availableStars,
                $currency . number_format($maxAmount, 2),
                $todayDate,
                "<span class='d-flex justify-content-end align-items-center'>{$action}</span>",
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function addManualStateAgentPayout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:tbl_users,id',
            'transferred_amount' => 'required|numeric|min:0.01',
            'paid_date' => 'required|date',
            'transaction_id' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $settings = GlobalSettings::first();
        $coinValue = floatval($settings->coin_value ?? 0);
        if ($coinValue <= 0) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid coin value in settings');
        }

        $user = Users::find(intval($request->user_id));
        $coins = intval(ceil(floatval($request->transferred_amount) / $coinValue));
        if ($coins > intval($user->coin_wallet ?? 0)) {
            return GlobalFunction::sendSimpleResponse(false, 'Transferred amount exceeds available stars');
        }

        DB::transaction(function () use ($user, $coins, $request) {
            $user->coin_wallet = intval($user->coin_wallet ?? 0) - $coins;
            $user->save();

            $payout = new ManualPayout();
            $payout->user_id = intval($user->id);
            $payout->coins = $coins;
            $payout->amount = round(floatval($request->transferred_amount), 2);
            $payout->paid_amount = round(floatval($request->transferred_amount), 2);
            $payout->commission_percent = 0;
            $payout->commission_amount = 0;
            $payout->transaction_id = trim($request->transaction_id);
            $payout->period_type = 'manual_state_agent';
            $payout->note = $request->description;
            $payout->payout_date = Carbon::parse($request->paid_date);
            $payout->save();
        });

        return GlobalFunction::sendSimpleResponse(true, 'State agent payout marked successfully');
    }

    public function listManualStateAgentPayouts(Request $request)
    {
        $query = ManualPayout::where('period_type', 'manual_state_agent');
        $totalData = $query->count();
        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');
        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('amount', 'LIKE', "%{$searchValue}%")
                    ->orWhere('note', 'LIKE', "%{$searchValue}%")
                    ->orWhere('transaction_id', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();
        $items = $query->offset($start)->limit($limit)->orderBy('id', 'DESC')->get();
        $settings = GlobalSettings::first();
        $currency = $settings->currency ?? '';

        $data = $items->map(function ($item) use ($currency) {
            $user = GlobalFunction::createUserDetailsColumn($item->user_id);
            return [
                "#{$item->id}",
                $user,
                intval($item->coins),
                $currency . number_format(floatval($item->amount ?? 0), 2),
                !empty($item->transaction_id) ? e($item->transaction_id) : '-',
                !empty($item->note) ? e($item->note) : '-',
                GlobalFunction::formateDatabaseTime($item->payout_date ?? $item->created_at),
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function listTodayGifterWalletPayout(Request $request)
    {
        $base = DB::table('tbl_gifter_return_wallets as gw')
            ->join('tbl_users as u', 'u.id', '=', 'gw.user_id')
            ->leftJoin('tbl_gift_categories as gc', 'gc.id', '=', 'gw.gift_category_id')
            ->where('u.is_dummy', 0);

        $totalData = (clone $base)
            ->select('gw.user_id', 'gw.gift_category_id')
            ->groupBy('gw.user_id', 'gw.gift_category_id')
            ->get()
            ->count();
        $searchValue = trim((string) $request->input('search.value'));
        if ($searchValue !== '') {
            $base->where(function ($q) use ($searchValue) {
                $q->where('u.id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('u.username', 'LIKE', "%{$searchValue}%")
                    ->orWhere('u.fullname', 'LIKE', "%{$searchValue}%")
                    ->orWhere('gc.name', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = (clone $base)
            ->select('gw.user_id', 'gw.gift_category_id')
            ->groupBy('gw.user_id', 'gw.gift_category_id')
            ->get()
            ->count();

        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $rows = $base->select(
            'u.id',
            'u.username',
            'u.fullname',
            'gw.gift_category_id',
            'gc.name as category_name',
            DB::raw('SUM(gw.stars) as wallet_stars')
        )
            ->groupBy('u.id', 'u.username', 'u.fullname', 'gw.gift_category_id', 'gc.name')
            ->orderByDesc('wallet_stars')
            ->offset($start)
            ->limit($limit)
            ->get();

        $todayDate = Carbon::now()->format('Y-m-d');
        $settings = GlobalSettings::first();
        $coinValue = floatval($settings->coin_value ?? 0);
        $currency = $settings->currency ?? '';

        $data = $rows->map(function ($item) use ($todayDate, $coinValue, $currency) {
            $displayName = trim((string) ($item->fullname ?: $item->username ?: ('User ' . $item->id))) . " ({$item->id})";
            $categoryName = trim((string) ($item->category_name ?? 'General'));
            if ($categoryName === '') {
                $categoryName = 'General';
            }
            $safeCategory = htmlspecialchars($categoryName, ENT_QUOTES, 'UTF-8');
            $categoryId = intval($item->gift_category_id ?? 0);
            $stars = intval($item->wallet_stars ?? 0);
            $maxAmount = round($stars * $coinValue, 2);
            $action = "<a href='#' class='action-btn use-for-gifter-wallet-payout d-flex align-items-center justify-content-center btn border rounded-2 text-primary ms-1' data-user-id='{$item->id}' data-category-id='{$categoryId}' data-category-name='{$safeCategory}' data-stars='{$stars}' data-max-amount='{$maxAmount}'><i class='uil-check-circle'></i></a>";

            return [
                e($displayName),
                e($categoryName),
                $stars,
                $currency . number_format($maxAmount, 2),
                $todayDate,
                "<span class='d-flex justify-content-end align-items-center'>{$action}</span>",
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function addManualGifterWalletPayout(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:tbl_users,id',
            'gift_category_id' => 'required|integer|min:0',
            'transferred_amount' => 'required|numeric|min:0.01',
            'paid_date' => 'required|date',
            'transaction_id' => 'required|string|max:255',
            'description' => 'nullable|string|max:1000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        if (!Schema::hasTable('tbl_gifter_return_wallets')) {
            return GlobalFunction::sendSimpleResponse(false, 'Gifter wallet table not found');
        }

        $settings = GlobalSettings::first();
        $coinValue = floatval($settings->coin_value ?? 0);
        if ($coinValue <= 0) {
            return GlobalFunction::sendSimpleResponse(false, 'Invalid coin value in settings');
        }

        $userId = intval($request->user_id);
        $giftCategoryId = intval($request->gift_category_id);
        $coins = intval(ceil(floatval($request->transferred_amount) / $coinValue));
        $availableQuery = DB::table('tbl_gifter_return_wallets')->where('user_id', $userId);
        $availableQuery->where('gift_category_id', $giftCategoryId);
        $availableStars = intval($availableQuery->sum('stars'));
        if ($coins > $availableStars) {
            return GlobalFunction::sendSimpleResponse(false, 'Transferred amount exceeds gifter wallet stars');
        }

        $categoryName = trim((string) GiftCategory::where('id', $giftCategoryId)->value('name'));
        if ($categoryName === '') {
            $categoryName = 'General';
        }

        DB::transaction(function () use ($userId, $giftCategoryId, $categoryName, $coins, $request) {
            $remaining = $coins;
            $rowsQuery = GifterReturnWallet::where('user_id', $userId)
                ->where('gift_category_id', $giftCategoryId);
            $rows = $rowsQuery->orderBy('gift_category_id', 'ASC')
                ->orderBy('id', 'ASC')
                ->get();

            foreach ($rows as $row) {
                if ($remaining <= 0) {
                    break;
                }
                $current = intval($row->stars ?? 0);
                if ($current <= 0) {
                    continue;
                }
                $deduct = min($current, $remaining);
                $row->stars = $current - $deduct;
                $row->save();
                $remaining -= $deduct;
            }

            $payout = new ManualPayout();
            $payout->user_id = $userId;
            $payout->coins = $coins;
            $payout->amount = round(floatval($request->transferred_amount), 2);
            $payout->paid_amount = round(floatval($request->transferred_amount), 2);
            $payout->commission_percent = 0;
            $payout->commission_amount = 0;
            $payout->transaction_id = trim($request->transaction_id);
            $payout->period_type = 'manual_gifter_wallet';
            $description = trim((string) $request->description);
            $payout->note = $description !== ''
                ? "[Category: {$categoryName}] {$description}"
                : "[Category: {$categoryName}]";
            $payout->payout_date = Carbon::parse($request->paid_date);
            $payout->save();
        });

        return GlobalFunction::sendSimpleResponse(true, 'Gifter wallet payout marked successfully');
    }

    public function listManualGifterWalletPayouts(Request $request)
    {
        $query = ManualPayout::where('period_type', 'manual_gifter_wallet');
        $totalData = $query->count();
        $limit = intval($request->input('length') ?? 10);
        $start = intval($request->input('start') ?? 0);
        $searchValue = $request->input('search.value');
        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('id', 'LIKE', "%{$searchValue}%")
                    ->orWhere('amount', 'LIKE', "%{$searchValue}%")
                    ->orWhere('note', 'LIKE', "%{$searchValue}%")
                    ->orWhere('transaction_id', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();
        $items = $query->offset($start)->limit($limit)->orderBy('id', 'DESC')->get();
        $settings = GlobalSettings::first();
        $currency = $settings->currency ?? '';

        $data = $items->map(function ($item) use ($currency) {
            $user = GlobalFunction::createUserDetailsColumn($item->user_id);
            return [
                "#{$item->id}",
                $user,
                intval($item->coins),
                $currency . number_format(floatval($item->amount ?? 0), 2),
                !empty($item->transaction_id) ? e($item->transaction_id) : '-',
                !empty($item->note) ? e($item->note) : '-',
                GlobalFunction::formateDatabaseTime($item->payout_date ?? $item->created_at),
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function sendGift(Request $request){
        Log::info('sendGift hit', [
            'user_id' => $request->input('user_id'),
            'gift_id' => $request->input('gift_id'),
            'source' => $request->input('source'),
            'request_time' => now()->toDateTimeString(),
        ]);

        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            Log::warning('sendGift aborted: user not found from authtoken');
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            Log::warning('sendGift aborted: user freezed', [
                'from_user_id' => intval($user->id),
            ]);
            return ['status' => false, 'message' => "this user is freezed!"];
        }
        $rules = [
            'user_id' => 'required|exists:tbl_users,id',
            'gift_id' => 'required|exists:tbl_gifts,id',
            'source' => 'nullable|in:chat_gift,audio_gift,video_gift',
            'language_id' => 'nullable|exists:languages,id',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            Log::warning('sendGift validation failed', [
                'from_user_id' => intval($user->id),
                'errors' => $validator->errors()->all(),
            ]);
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }
        $dataUser = GlobalFunction::prepareUserFullData($request->user_id);
        $gift = Gifts::find($request->gift_id);
        $giftCategoryId = intval($gift->gift_category_id ?? 0);
        $giftCategoryName = null;
        if ($giftCategoryId > 0) {
            $giftCategoryName = GiftCategory::where('id', $giftCategoryId)->value('name');
        }
        $settings = GlobalSettings::first();
        $diamondToStarRate = floatval($settings->diamond_to_star_rate ?? 1);
        if ($diamondToStarRate <= 0) {
            $diamondToStarRate = 1;
        }

        $giftStars = intval($gift->coin_price);
        $giftDiamondPrice = intval($gift->diamond_price ?? 0);
        $requiredDiamonds = $giftDiamondPrice > 0
            ? $giftDiamondPrice
            : intval(ceil($giftStars / $diamondToStarRate));
        $hostCommission = max(0, floatval($settings->host_commission ?? 0));
        $adminCommission = max(0, floatval($settings->admin_commision ?? 0));
        $agentCommission = max(0, floatval($settings->agent_commision ?? 0));
        $stateAgentCommission = max(0, floatval($settings->state_agent_commision ?? 0));
        $gifterReturnPercent = max(0, floatval($settings->gifter_return ?? 0));
        $giftSource = trim((string) ($request->source ?? ''));
        if ($giftSource === '') {
            $giftSource = 'chat_gift';
        }
        // Self check
         if($user->id == $dataUser->id){
            Log::warning('sendGift aborted: self gift attempt', [
                'from_user_id' => intval($user->id),
                'to_user_id' => intval($dataUser->id),
            ]);
            return GlobalFunction::sendSimpleResponse(false, 'you can not gift yourself!');
        }
        if(intval($user->diamond_wallet ?? 0) < $requiredDiamonds){
            Log::warning('sendGift aborted: insufficient diamonds', [
                'from_user_id' => intval($user->id),
                'required_diamonds' => intval($requiredDiamonds),
                'available_diamonds' => intval($user->diamond_wallet ?? 0),
            ]);
            return GlobalFunction::sendSimpleResponse(false, 'not enough diamonds in your wallet!');
        }

        $distributionBase = intval($giftStars);
        $hostStars = intval(floor(($distributionBase * $hostCommission) / 100));
        $adminStars = intval(floor(($distributionBase * $adminCommission) / 100));
        $agentStars = intval(floor(($distributionBase * $agentCommission) / 100));
        $stateAgentStars = intval(floor(($distributionBase * $stateAgentCommission) / 100));

        // Do not distribute more than available stars across receiver/admin/agent/state-agent shares.
        $totalMainSplit = $hostStars + $adminStars + $agentStars + $stateAgentStars;
        if ($totalMainSplit > $distributionBase) {
            $overflow = $totalMainSplit - $distributionBase;
            if ($overflow > 0) {
                $reduce = min($stateAgentStars, $overflow);
                $stateAgentStars -= $reduce;
                $overflow -= $reduce;
            }
            if ($overflow > 0) {
                $reduce = min($agentStars, $overflow);
                $agentStars -= $reduce;
                $overflow -= $reduce;
            }
            if ($overflow > 0) {
                $reduce = min($adminStars, $overflow);
                $adminStars -= $reduce;
                $overflow -= $reduce;
            }
            if ($overflow > 0) {
                $reduce = min($hostStars, $overflow);
                $hostStars -= $reduce;
            }
        }

        $gifterReturnStars = intval(floor(($distributionBase * $gifterReturnPercent) / 100));
        $adminWalletAfter = intval($settings->admin_wallet ?? 0);
        $senderAgentId = intval($user->agent_id ?? 0);
        $stateAgentId = $this->resolveStateAgentIdByAgentId($senderAgentId);
        $agentWalletAfter = null;
        $stateAgentWalletAfter = null;
        $gifterReturnCategoryWalletStars = null;
        $notificationData = null;

        DB::transaction(function () use (
            &$user,
            &$dataUser,
            &$settings,
            &$adminWalletAfter,
            &$agentWalletAfter,
            &$stateAgentWalletAfter,
            &$gifterReturnCategoryWalletStars,
            &$notificationData,
            $requiredDiamonds,
            $giftStars,
            $giftSource,
            $gift,
            $hostStars,
            $adminStars,
            $agentStars,
            $stateAgentStars,
            $senderAgentId,
            $stateAgentId,
            $gifterReturnStars,
            $giftCategoryId,
            $gifterReturnPercent
        ) {
            $user = Users::where('id', $user->id)->lockForUpdate()->first();
            $dataUser = Users::where('id', $dataUser->id)->lockForUpdate()->first();
            $settings = GlobalSettings::query()->lockForUpdate()->first();

            $user->diamond_wallet = intval($user->diamond_wallet ?? 0) - $requiredDiamonds;
            $user->diamond_spent_lifetime = intval($user->diamond_spent_lifetime ?? 0) + $requiredDiamonds;
            $user->coin_gifted_lifetime = intval($user->coin_gifted_lifetime ?? 0) + $giftStars;
            $user->save();

            $diamondTransaction = $this->createDiamondTransaction(
                $user,
                Constants::debit,
                $requiredDiamonds,
                $giftSource,
                'gift',
                intval($gift->id),
                'Gift sent'
            );

            $spend = new DiamondSpendHistory();
            $spend->user_id = intval($user->id);
            $spend->diamonds = $requiredDiamonds;
            $spend->purpose = $giftSource;
            $spend->reference_type = 'gift';
            $spend->reference_id = intval($gift->id);
            $spend->transaction_id = intval($diamondTransaction->id ?? 0);
            $spend->note = 'Gift sent';
            $spend->save();

            // Host(receiver) split
            if ($hostStars > 0) {
                $dataUser->coin_wallet = intval($dataUser->coin_wallet ?? 0) + $hostStars;
                $dataUser->coin_collected_lifetime = intval($dataUser->coin_collected_lifetime ?? 0) + $hostStars;
                $dataUser->save();
            }

            // Admin split into settings wallet
            if ($adminStars > 0 && Schema::hasColumn('tbl_settings', 'admin_wallet')) {
                $settings->admin_wallet = intval($settings->admin_wallet ?? 0) + $adminStars;
                $settings->save();
                $adminWalletAfter = intval($settings->admin_wallet ?? 0);
            }

            // Sender's agent commission
            if ($agentStars > 0 && $senderAgentId > 0) {
                $agentUser = Users::where('id', $senderAgentId)->lockForUpdate()->first();
                if ($agentUser) {
                    $agentUser->agent_commission_wallet = round(floatval($agentUser->agent_commission_wallet ?? 0) + $agentStars, 2);
                    $agentUser->save();

                    $entry = new AgentCommissionEntries();
                    $entry->agent_id = intval($agentUser->id);
                    $entry->user_id = intval($user->id);
                    $entry->diamond_transaction_id = intval($diamondTransaction->id ?? 0);
                    $entry->purchase_amount = round(floatval($giftStars), 2);
                    $entry->commission_percent = round(floatval($agentCommission), 2);
                    $entry->commission_amount = round(floatval($agentStars), 2);
                    $entry->note = 'Gift commission';
                    $entry->save();

                    $agentWalletAfter = round(floatval($agentUser->agent_commission_wallet ?? 0), 2);
                }
            }

            // Sender's state agent commission
            if ($stateAgentStars > 0 && $stateAgentId > 0) {
                $stateAgentUser = Users::where('id', $stateAgentId)->lockForUpdate()->first();
                if ($stateAgentUser) {
                    $stateAgentUser->agent_commission_wallet = round(floatval($stateAgentUser->agent_commission_wallet ?? 0) + $stateAgentStars, 2);
                    $stateAgentUser->save();

                    $entry = new AgentCommissionEntries();
                    $entry->agent_id = intval($stateAgentUser->id);
                    $entry->user_id = intval($user->id);
                    $entry->diamond_transaction_id = intval($diamondTransaction->id ?? 0);
                    $entry->purchase_amount = round(floatval($giftStars), 2);
                    $entry->commission_percent = round(floatval($stateAgentCommission), 2);
                    $entry->commission_amount = round(floatval($stateAgentStars), 2);
                    $entry->note = 'Gift state agent commission';
                    $entry->save();

                    $stateAgentWalletAfter = round(floatval($stateAgentUser->agent_commission_wallet ?? 0), 2);
                }
            }

            // Configured gifter return is stored only in the separate category-wise wallet.
            if ($gifterReturnStars > 0 && Schema::hasTable('tbl_gifter_return_wallets')) {
                $walletCategoryId = $giftCategoryId > 0 ? $giftCategoryId : 0;
                $gifterWallet = GifterReturnWallet::firstOrNew([
                    'user_id' => intval($user->id),
                    'gift_category_id' => $walletCategoryId,
                ]);
                $gifterWallet->stars = intval($gifterWallet->stars ?? 0) + $gifterReturnStars;
                $gifterWallet->save();
                $gifterReturnCategoryWalletStars = intval($gifterWallet->stars ?? 0);

                Log::info('Gift gifter return credited', [
                    'sender_user_id' => intval($user->id),
                    'receiver_user_id' => intval($dataUser->id),
                    'gift_id' => intval($gift->id),
                    'gift_category_id' => $walletCategoryId,
                    'gifter_return_percent' => round(floatval($gifterReturnPercent), 2),
                    'gifter_return_stars' => intval($gifterReturnStars),
                    'gifter_return_category_wallet_stars' => intval($gifterReturnCategoryWalletStars),
                ]);
            } else {
                Log::info('Gift gifter return skipped', [
                    'sender_user_id' => intval($user->id),
                    'receiver_user_id' => intval($dataUser->id),
                    'gift_id' => intval($gift->id),
                    'gift_category_id' => $giftCategoryId > 0 ? intval($giftCategoryId) : 0,
                    'gifter_return_percent' => round(floatval($gifterReturnPercent), 2),
                    'gifter_return_stars' => intval($gifterReturnStars),
                    'gifter_wallet_table_exists' => Schema::hasTable('tbl_gifter_return_wallets'),
                ]);
            }

            // Insert Notification Data : Gift Sent
            $notificationData = GlobalFunction::insertUserNotification(Constants::notify_gift_user, $user->id, $dataUser->id, $gift->id, $giftSource);

            // Powers the leaderboard's language filter — the room's language,
            // which no other column on this row captures.
            if ($notificationData && $request->filled('language_id') && Schema::hasColumn('notification_users', 'language_id')) {
                $notificationData->language_id = intval($request->language_id);
                $notificationData->save();
            }
        });

        try {
            if (!empty($dataUser->device_token)) {
                $senderName = trim((string) ($user->fullname ?: $user->username ?: ('User #' . $user->id)));
                $giftTitle = trim((string) ($gift->title ?? 'Gift'));
                $title = 'Gift Received';
                $description = $senderName . ' sent you a gift';

                if ($giftTitle !== '' && strtolower($giftTitle) !== 'gift') {
                    $description .= ': ' . $giftTitle;
                }

                $pushData = [
                    'screen' => 'notifications',
                    'route' => 'notifications',
                    'gift_id' => (string) intval($gift->id),
                    'user_id' => (string) intval($user->id),
                    'notify_type' => (string) Constants::notify_gift_user,
                    'source' => (string) $giftSource,
                ];

                if ($notificationData) {
                    $pushData['notification_id'] = (string) intval($notificationData->id);
                }

                $payload = GlobalFunction::generatePushNotificationPayload(
                    intval($dataUser->device ?? Constants::android),
                    Constants::pushTypeToken,
                    $dataUser->device_token,
                    $title,
                    $description,
                    null,
                    $pushData
                );

                GlobalFunction::sendPushNotification($payload);
            }
        } catch (Throwable $e) {
            Log::error('Gift push notification failed', [
                'from_user_id' => intval($user->id),
                'to_user_id' => intval($dataUser->id),
                'gift_id' => intval($gift->id),
                'error' => $e->getMessage(),
            ]);
        }

        GlobalFunction::autoUpgradeUserLevel($user->id);

        Log::info('sendGift completed', [
            'from_user_id' => intval($user->id),
            'to_user_id' => intval($dataUser->id),
            'gift_id' => intval($gift->id),
            'required_diamonds' => intval($requiredDiamonds),
            'host_stars' => intval($hostStars),
            'admin_stars' => intval($adminStars),
            'agent_stars' => intval($agentStars),
            'state_agent_stars' => intval($stateAgentStars),
            'gifter_return_stars' => intval($gifterReturnStars),
        ]);

        return GlobalFunction::sendDataResponse(true, 'gift sent successfully!', [
            'gift_id' => intval($gift->id),
            'gift_stars' => intval($giftStars),
            'gift_diamond_price' => intval($requiredDiamonds),
            'diamonds_spent' => intval($requiredDiamonds),
            'source' => $giftSource,
            'category_id' => $giftCategoryId > 0 ? $giftCategoryId : null,
            'category_name' => $giftCategoryName,
            'distribution' => [
                'host_stars' => intval($hostStars),
                'admin_stars' => intval($adminStars),
                'agent_stars' => intval($agentStars),
                'state_agent_stars' => intval($stateAgentStars),
                'gifter_return_stars' => intval($gifterReturnStars),
            ],
            'from_user_diamond_wallet' => intval($user->diamond_wallet ?? 0),
            'to_user_star_wallet' => intval($dataUser->coin_wallet ?? 0),
            'admin_wallet' => $adminWalletAfter,
            'sender_agent_id' => $senderAgentId > 0 ? $senderAgentId : null,
            'sender_agent_commission_wallet' => $agentWalletAfter,
            'state_agent_id' => $stateAgentId > 0 ? $stateAgentId : null,
            'state_agent_commission_wallet' => $stateAgentWalletAfter,
            'gifter_return_category_wallet_stars' => $gifterReturnCategoryWalletStars,
        ]);
    }

    public function fetchGiftProfit(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        if (!Schema::hasTable('tbl_gifter_return_wallets')) {
            return response()->json([
                'status' => true,
                'data' => [],
            ]);
        }

        $rows = DB::table('tbl_gifter_return_wallets as gr')
            ->leftJoin('tbl_gift_categories as gc', 'gc.id', '=', 'gr.gift_category_id')
            ->where('gr.user_id', intval($user->id))
            ->select(
                'gr.gift_category_id as category_id',
                DB::raw('COALESCE(gc.name, "Uncategorized") as category_name'),
                DB::raw('SUM(gr.stars) as total_coins')
            )
            ->groupBy('gr.gift_category_id', 'gc.name')
            ->orderBy('gr.gift_category_id', 'ASC')
            ->get()
            ->map(function ($item) {
                return [
                    'category_id' => intval($item->category_id),
                    'category_name' => (string) $item->category_name,
                    'total_coins' => intval($item->total_coins),
                ];
            })
            ->values();

        return response()->json([
            'status' => true,
            'data' => $rows,
        ]);
    }

    /// `type` maps a leaderboard tab onto the gift ledger's `source` column,
    /// which the mobile app tags at gift-send time.
    private function giftSourcesForType(?string $type): ?array
    {
        switch (strtolower(trim((string) $type))) {
            case 'video':
                return ['video_gift'];
            case 'audio':
                return ['audio_gift'];
            default:
                return null;
        }
    }

    private function applyLeaderboardFilters($query, ?string $type, $languageId)
    {
        $sources = $this->giftSourcesForType($type);
        if ($sources !== null && Schema::hasColumn('notification_users', 'source')) {
            $query->whereIn('n.source', $sources);
        }
        if (!empty($languageId) && Schema::hasColumn('notification_users', 'language_id')) {
            $query->where('n.language_id', intval($languageId));
        }
        return $query;
    }

    private function followingIdsOf($userId): array
    {
        return DB::table('tbl_followers')
            ->where('from_user_id', $userId)
            ->pluck('to_user_id')
            ->map(fn($id) => intval($id))
            ->all();
    }

    public function fetchTopGifters(Request $request)
    {
        $me = GlobalFunction::getUserFromAuthToken($request->header('authtoken'));
        if (!$me) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }

        $rules = [
            'period' => 'nullable|in:today,yesterday,this_week,this_month,all_time',
            'type' => 'nullable|in:video,audio',
            'language_id' => 'nullable|exists:languages,id',
            'limit' => 'nullable|integer|min:1|max:100',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $period = $request->period ?? 'today';
        $limit = intval($request->limit ?? 20);
        [$start, $end] = $this->resolvePeriodRange($period);

        $query = DB::table('notification_users as n')
            ->join('tbl_users as u', 'u.id', '=', 'n.from_user_id')
            ->join('tbl_gifts as g', 'g.id', '=', 'n.data_id')
            ->leftJoin('user_levels as ul', 'ul.id', '=', 'u.level_id')
            ->where('n.type', Constants::notify_gift_user)
            ->whereBetween('n.created_at', [$start, $end]);
        $this->applyLeaderboardFilters($query, $request->type, $request->language_id);

        $rows = $query
            ->select(
                'u.id',
                'u.username',
                'u.fullname',
                'u.profile_photo',
                'ul.level as user_level',
                DB::raw('SUM(g.coin_price) as total_stars')
            )
            ->groupBy('u.id', 'u.username', 'u.fullname', 'u.profile_photo', 'ul.level')
            ->orderByDesc('total_stars')
            ->get()
            ->values();

        $followingIds = $this->followingIdsOf($me->id);

        $data = $rows->map(function ($item, $index) use ($followingIds) {
            return [
                'rank' => $index + 1,
                'user_id' => intval($item->id),
                'username' => $item->username,
                'fullname' => $item->fullname,
                'profile_photo' => !empty($item->profile_photo) ? GlobalFunction::generateFileUrl($item->profile_photo) : null,
                'user_level' => intval($item->user_level ?? 0),
                'total_stars' => intval($item->total_stars),
                'is_following' => in_array(intval($item->id), $followingIds, true),
            ];
        });

        return response()->json([
            'status' => true,
            'message' => 'Top gifters fetched successfully',
            'data' => $data->take($limit)->values(),
            'my_rank' => $data->firstWhere('user_id', intval($me->id)),
        ]);
    }

    public function fetchTopHosts(Request $request)
    {
        $me = GlobalFunction::getUserFromAuthToken($request->header('authtoken'));
        if (!$me) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }

        $rules = [
            'period' => 'nullable|in:today,yesterday,this_week,this_month,all_time',
            'type' => 'nullable|in:video,audio',
            'language_id' => 'nullable|exists:languages,id',
            'limit' => 'nullable|integer|min:1|max:100',
        ];
        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $period = $request->period ?? 'today';
        $limit = intval($request->limit ?? 20);
        [$start, $end] = $this->resolvePeriodRange($period);

        $query = DB::table('notification_users as n')
            ->join('tbl_users as u', 'u.id', '=', 'n.to_user_id')
            ->join('tbl_gifts as g', 'g.id', '=', 'n.data_id')
            ->leftJoin('user_levels as ul', 'ul.id', '=', 'u.level_id')
            ->where('n.type', Constants::notify_gift_user)
            ->where('u.is_host', 1)
            ->whereBetween('n.created_at', [$start, $end]);
        $this->applyLeaderboardFilters($query, $request->type, $request->language_id);

        $rows = $query
            ->select(
                'u.id',
                'u.username',
                'u.fullname',
                'u.profile_photo',
                'u.coin_wallet',
                'ul.level as user_level',
                DB::raw('SUM(g.coin_price) as total_stars')
            )
            ->groupBy('u.id', 'u.username', 'u.fullname', 'u.profile_photo', 'u.coin_wallet', 'ul.level')
            ->orderByDesc('total_stars')
            ->get()
            ->values();

        $followingIds = $this->followingIdsOf($me->id);

        $data = $rows->map(function ($item, $index) use ($followingIds) {
            return [
                'rank' => $index + 1,
                'user_id' => intval($item->id),
                'username' => $item->username,
                'fullname' => $item->fullname,
                'profile_photo' => !empty($item->profile_photo) ? GlobalFunction::generateFileUrl($item->profile_photo) : null,
                'user_level' => intval($item->user_level ?? 0),
                'is_host' => 1,
                'total_stars' => intval($item->total_stars),
                'coin_wallet' => intval($item->coin_wallet),
                'is_following' => in_array(intval($item->id), $followingIds, true),
            ];
        });

        return response()->json([
            'status' => true,
            'message' => 'Top hosts fetched successfully',
            'data' => $data->take($limit)->values(),
            'my_rank' => $data->firstWhere('user_id', intval($me->id)),
        ]);
    }

    public function fetchAgentCommission(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }
        if (intval($user->is_agent ?? 0) !== 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Only agent can access this API');
        }

        $validator = Validator::make($request->all(), [
            'limit' => 'nullable|integer|min:1|max:100',
            'last_item_id' => 'nullable|integer|min:1',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $limit = intval($request->limit ?? 20);
        $settings = GlobalSettings::first();
        $commissionRate = floatval($settings->agent_commission ?? 0);

        $totalCommission = AgentCommissionEntries::where('agent_id', $user->id)->sum('commission_amount');
        $paidCommission = ManualPayout::where('user_id', $user->id)
            ->where('period_type', 'manual_agent')
            ->sum('amount');
        $balanceCommission = round(floatval($user->agent_commission_wallet ?? 0), 2);

        $query = AgentCommissionEntries::where('agent_id', $user->id)
            ->orderBy('id', 'DESC')
            ->limit($limit);

        if ($request->filled('last_item_id')) {
            $query->where('id', '<', intval($request->last_item_id));
        }

        $items = $query->get();
        $buyerIds = $items->pluck('user_id')->filter()->unique()->values();
        $buyers = Users::whereIn('id', $buyerIds)->get(['id', 'fullname', 'username', 'profile_photo'])->keyBy('id');

        $transactions = $items->map(function ($item) use ($buyers) {
            $buyer = $buyers[$item->user_id] ?? null;
            $diamondAmount = 0;
            if (!empty($item->diamond_transaction_id)) {
                $diamondAmount = intval(
                    DiamondTransactions::where('id', $item->diamond_transaction_id)->value('diamonds') ?? 0
                );
            }

            return [
                'id' => intval($item->id),
                'user_id' => intval($item->user_id ?? 0),
                'fullname' => $buyer->fullname ?? null,
                'username' => $buyer->username ?? null,
                'profile_photo' => $buyer->profile_photo ?? null,
                'diamond_amount' => $diamondAmount,
                'commission_earned' => floatval($item->commission_amount ?? 0),
                'created_at' => !empty($item->created_at) ? Carbon::parse($item->created_at)->format('Y-m-d H:i:s') : null,
            ];
        })->values();

        return response()->json([
            'status' => true,
            'message' => 'Success',
            'data' => [
                'total_commission' => round(floatval($totalCommission), 2),
                'paid_commission' => round(floatval($paidCommission), 2),
                'balance_commission' => $balanceCommission,
                'commission_rate' => $commissionRate,
                'minimum_withdraw_limit' => round(floatval($settings->agent_commission_min_withdraw ?? 0), 2),
                'transactions' => $transactions,
            ],
        ]);
    }
}
