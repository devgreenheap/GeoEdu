<?php

namespace App\Http\Controllers;

use App\Models\AgentCommissionEntries;
use App\Models\Constants;
use App\Models\GlobalSettings;
use App\Models\GlobalFunction;
use App\Models\GifterReturnWallet;
use App\Models\ManualPayout;
use App\Models\Posts;
use App\Models\ReportPosts;
use App\Models\ReportUsers;
use App\Models\StateMaster;
use App\Models\Users;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Validator;

class ReportController extends Controller
{
    //
    private function renderReportsWithTab(string $tab)
    {
        return view('reports', ['activeReportTab' => $tab]);
    }

    private function resolveDateRange(Request $request): array
    {
        $start = trim((string) $request->input('start_date', ''));
        $end = trim((string) $request->input('end_date', ''));

        if ($start !== '' && $end !== '') {
            try {
                return [
                    Carbon::parse($start)->startOfDay(),
                    Carbon::parse($end)->endOfDay(),
                ];
            } catch (\Throwable $e) {
                // fallback to default range
            }
        }

        return [
            Carbon::now()->subDays(30)->startOfDay(),
            Carbon::now()->endOfDay(),
        ];
    }

    private function dataTableFromRows(Request $request, array $rows, int $searchableColumn = 0)
    {
        $draw = intval($request->input('draw'));
        $start = intval($request->input('start') ?? 0);
        $length = intval($request->input('length') ?? 10);
        $searchValue = strtolower(trim((string) $request->input('search.value')));

        $filteredRows = $rows;
        if ($searchValue !== '') {
            $filteredRows = array_values(array_filter($rows, function ($row) use ($searchValue, $searchableColumn) {
                $cell = strtolower(strip_tags((string) ($row[$searchableColumn] ?? '')));
                return str_contains($cell, $searchValue);
            }));
        }

        $total = count($rows);
        $totalFiltered = count($filteredRows);
        $paged = array_slice($filteredRows, $start, $length);

        return response()->json([
            'draw' => $draw,
            'recordsTotal' => $total,
            'recordsFiltered' => $totalFiltered,
            'data' => array_values($paged),
        ]);
    }

    public function reports(){
        return $this->renderReportsWithTab('revenue');
    }

    public function reportRevenueCommission()
    {
        return $this->renderReportsWithTab('revenue');
    }

    public function reportPayoutControl()
    {
        return $this->renderReportsWithTab('payout');
    }

    public function reportLivePerformance()
    {
        return $this->renderReportsWithTab('live');
    }

    public function reportUserGrowthQuality()
    {
        return $this->renderReportsWithTab('growth');
    }

    public function reportGiftAnalytics()
    {
        return $this->renderReportsWithTab('gift');
    }

    public function reportAgentStatePerformance()
    {
        return $this->renderReportsWithTab('agent');
    }

    public function reportModerationRisk()
    {
        return $this->renderReportsWithTab('moderation');
    }
    public function reportUser(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'user_id' =>'required|exists:tbl_users,id',
            'reason' =>'required',
            'description' =>'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->all()]);
        }

       $report = ReportUsers::where([
        'user_id'=> $request->user_id,
        'by_user_id'=> $user->id,
       ])->first();
       if($report != null){
        return GlobalFunction::sendSimpleResponse(false,'you have reported this user already!');
       }
       $report = new ReportUsers();
       $report->user_id = $request->user_id;
       $report->by_user_id = $user->id;
       $report->reason = $request->reason;
       $report->description = $request->description;
       $report->save();

    return GlobalFunction::sendSimpleResponse(true, 'user report submitted successfully');

    }
    public function rejectUserReport(Request $request){

        $report = ReportUsers::find($request->id);
        $report->delete();

        return GlobalFunction::sendSimpleResponse(true,'Report rejected successfully!');
    }
    public function acceptUserReport(Request $request){

        $report = ReportUsers::find($request->id);
        $user = Users::find($report->user_id);
        $user->is_freez = 1;
        $user->save();

        $report->delete();

        return GlobalFunction::sendSimpleResponse(true,'User freezed successfully!');
    }
    public function acceptPostReport(Request $request){

        $report = ReportPosts::find($request->id);

        $post = Posts::find($report->post_id);
        $post->delete();
        GlobalFunction::deleteAllPostData($post);

        return GlobalFunction::sendSimpleResponse(true,'Post deleted successfully!');
    }
    public function rejectPostReport(Request $request){
        $report = ReportPosts::find($request->id);
        $report->delete();

        return GlobalFunction::sendSimpleResponse(true,'Report rejected successfully!');
    }
    public function listUserReports(Request $request)
    {
        $query = ReportUsers::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('reason', 'LIKE', "%{$searchValue}%")
                ->orWhere('description', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->map(function ($item) {

            $acceptReport = "<a href='#'
                          rel='{$item->id}'
                          style='width:110px'
                          class='mb-1 action-btn-text accept-report d-flex align-items-center justify-content-center border rounded-2 text-success ms-1'>
                            Accept Report
                        </a>";
            $rejectReport = "<a href='#'
                          rel='{$item->id}'
                          style='width:110px'
                          class='action-btn-text reject-report d-flex align-items-center justify-content-center border rounded-2 text-danger ms-1'>
                            Reject Report
                        </a>";

            $action = "<div class='float-end'>{$acceptReport}{$rejectReport}</div>";

            $user = GlobalFunction::createUserDetailsColumn($item->user_id);
            $reportedBy = GlobalFunction::createUserDetailsColumn($item->by_user_id);

            $reason = "<h5>{$item->reason}</h5>";
            $description = "<p>{$item->description}</p>";

            $details = '<div class="reportDescription">'.$reason.$description.'</div>';

            return [
                $user,
                $details,
                $reportedBy,
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
    public function listPostReports(Request $request)
    {
        $query = ReportPosts::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('reason', 'LIKE', "%{$searchValue}%")
                ->orWhere('description', 'LIKE', "%{$searchValue}%");
            });
        }
        $totalFiltered = $query->count();

        $result = $query->offset($start)
                        ->limit($limit)
                        ->orderBy('id', 'DESC')
                        ->get();

        $data = $result->map(function ($item) {

            $post = $item->post;

            $acceptReport = "<a href='#'
                          rel='{$item->id}'
                          style='width:110px'
                          class='mb-1 action-btn-text accept-report d-flex align-items-center justify-content-center border rounded-2 text-success ms-1'>
                            Accept Report
                        </a>";
            $rejectReport = "<a href='#'
                          rel='{$item->id}'
                          style='width:110px'
                          class='action-btn-text reject-report d-flex align-items-center justify-content-center border rounded-2 text-danger ms-1'>
                            Reject Report
                        </a>";

            $action = "<div class='float-end'>{$acceptReport}{$rejectReport}</div>";

            $postUser = GlobalFunction::createUserDetailsColumn($post->user_id);

            $reportedBy = GlobalFunction::createUserDetailsColumn($item->by_user_id);

            // View Content Button
            $viewContent = GlobalFunction::createViewContentButton($post);

            $reason = "<h5>{$item->reason}</h5>";
            $description = "<p>{$item->description}</p>";

            $details = '<div class="reportDescription">'.$reason.$description.'</div>';

            return [
                $viewContent,
                $postUser,
                $details,
                $reportedBy,
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

    public function listRevenueCommissionReport(Request $request)
    {
        [$startDate, $endDate] = $this->resolveDateRange($request);

        $totalGiftDiamonds = floatval(
            DB::table('notification_users as n')
                ->join('tbl_gifts as g', 'g.id', '=', 'n.data_id')
                ->where('n.type', Constants::notify_gift_user)
                ->whereBetween('n.created_at', [$startDate, $endDate])
                ->sum('g.coin_price')
        );

        $settings = GlobalSettings::first();
        $hostPercent = floatval($settings->host_commission ?? 0);
        $adminPercent = floatval($settings->admin_commision ?? 0);
        $agentPercent = floatval($settings->agent_commision ?? 0);
        $stateAgentPercent = floatval($settings->state_agent_commision ?? 0);
        $gifterReturnPercent = floatval($settings->gifter_return ?? 0);

        $hostShare = round(($totalGiftDiamonds * $hostPercent) / 100, 2);
        $adminShare = round(($totalGiftDiamonds * $adminPercent) / 100, 2);
        $agentShare = round(($totalGiftDiamonds * $agentPercent) / 100, 2);
        $stateAgentShare = round(($totalGiftDiamonds * $stateAgentPercent) / 100, 2);
        $gifterReturnShare = round(($totalGiftDiamonds * $gifterReturnPercent) / 100, 2);

        $actualAgentCommission = round(floatval(
            AgentCommissionEntries::whereBetween('created_at', [$startDate, $endDate])->sum('commission_amount')
        ), 2);

        $rows = [
            ['Total Gift Diamonds', GlobalFunction::formatNumber($totalGiftDiamonds), 'Gross diamonds from gifts'],
            ["Host Commission ({$hostPercent}%)", GlobalFunction::formatNumber($hostShare), 'Estimated by settings'],
            ["Admin Commission ({$adminPercent}%)", GlobalFunction::formatNumber($adminShare), 'Estimated by settings'],
            ["Agent Commission ({$agentPercent}%)", GlobalFunction::formatNumber($agentShare), 'Estimated by settings'],
            ['Agent Commission (Actual)', GlobalFunction::formatNumber($actualAgentCommission), 'From agent commission entries'],
            ["State Agent Commission ({$stateAgentPercent}%)", GlobalFunction::formatNumber($stateAgentShare), 'Estimated by settings'],
            ["Gifter Return ({$gifterReturnPercent}%)", GlobalFunction::formatNumber($gifterReturnShare), 'Estimated by settings'],
        ];

        return $this->dataTableFromRows($request, $rows);
    }

    public function listPayoutControlReport(Request $request)
    {
        [$startDate, $endDate] = $this->resolveDateRange($request);

        $settings = GlobalSettings::first();
        $coinValue = floatval($settings->coin_value ?? 0);

        $paidByType = ManualPayout::selectRaw('period_type, SUM(amount) as total_amount')
            ->whereBetween(DB::raw('COALESCE(payout_date, created_at)'), [$startDate, $endDate])
            ->groupBy('period_type')
            ->pluck('total_amount', 'period_type');

        $lastPaidAt = ManualPayout::selectRaw('period_type, MAX(COALESCE(payout_date, created_at)) as last_paid_at')
            ->groupBy('period_type')
            ->pluck('last_paid_at', 'period_type');

        $stateAgentIds = StateMaster::whereNotNull('agent_id')
            ->where('agent_id', '>', 0)
            ->distinct()
            ->pluck('agent_id')
            ->map(fn($id) => intval($id))
            ->filter(fn($id) => $id > 0)
            ->values()
            ->toArray();

        $pendingHost = round(floatval(Users::where('is_dummy', 0)->sum('coin_wallet')) * $coinValue, 2);
        $pendingAdmin = round(floatval($settings->admin_wallet ?? 0), 2);
        $pendingAgent = round(floatval(Users::where('is_agent', 1)->sum('agent_commission_wallet')), 2);
        $pendingStateAgent = round(floatval(
            empty($stateAgentIds) ? 0 : Users::whereIn('id', $stateAgentIds)->sum('coin_wallet')
        ) * $coinValue, 2);
        $pendingGifterWallet = round(floatval(GifterReturnWallet::sum('stars')) * $coinValue, 2);

        $rows = [
            [
                'Host Payout',
                GlobalFunction::formatNumber($pendingHost),
                GlobalFunction::formatNumber(floatval($paidByType['manual_user'] ?? $paidByType['manual'] ?? 0)),
                !empty($lastPaidAt['manual_user']) ? GlobalFunction::formateDatabaseTime($lastPaidAt['manual_user']) : '-',
            ],
            [
                'Admin Payout',
                GlobalFunction::formatNumber($pendingAdmin),
                GlobalFunction::formatNumber(floatval($paidByType['manual_admin'] ?? 0)),
                !empty($lastPaidAt['manual_admin']) ? GlobalFunction::formateDatabaseTime($lastPaidAt['manual_admin']) : '-',
            ],
            [
                'Agent Payout',
                GlobalFunction::formatNumber($pendingAgent),
                GlobalFunction::formatNumber(floatval($paidByType['manual_agent'] ?? 0)),
                !empty($lastPaidAt['manual_agent']) ? GlobalFunction::formateDatabaseTime($lastPaidAt['manual_agent']) : '-',
            ],
            [
                'State Agent Payout',
                GlobalFunction::formatNumber($pendingStateAgent),
                GlobalFunction::formatNumber(floatval($paidByType['manual_state_agent'] ?? 0)),
                !empty($lastPaidAt['manual_state_agent']) ? GlobalFunction::formateDatabaseTime($lastPaidAt['manual_state_agent']) : '-',
            ],
            [
                'Gifter Wallet Payout',
                GlobalFunction::formatNumber($pendingGifterWallet),
                GlobalFunction::formatNumber(floatval($paidByType['manual_gifter_wallet'] ?? 0)),
                !empty($lastPaidAt['manual_gifter_wallet']) ? GlobalFunction::formateDatabaseTime($lastPaidAt['manual_gifter_wallet']) : '-',
            ],
        ];

        return $this->dataTableFromRows($request, $rows);
    }

    public function listLivePerformanceReport(Request $request)
    {
        [$startDate, $endDate] = $this->resolveDateRange($request);

        $items = DB::table('tbl_live_streams as ls')
            ->join('tbl_users as u', 'u.id', '=', 'ls.user_id')
            ->whereBetween('ls.started_at', [$startDate, $endDate])
            ->select(
                'ls.user_id',
                'u.username',
                'u.fullname',
                DB::raw('COUNT(*) as total_lives'),
                DB::raw('SUM(CASE WHEN ls.status = 0 THEN 1 ELSE 0 END) as ended_lives'),
                DB::raw('SUM(ls.duration) as total_duration_seconds'),
                DB::raw('AVG(ls.duration) as avg_duration_seconds')
            )
            ->groupBy('ls.user_id', 'u.username', 'u.fullname')
            ->orderByDesc('total_lives')
            ->get();

        $rows = $items->map(function ($item) {
            $hostName = e(trim((string) ($item->fullname ?: $item->username ?: ('User ' . $item->user_id)))) . " ({$item->user_id})";
            return [
                $hostName,
                intval($item->total_lives ?? 0),
                intval($item->ended_lives ?? 0),
                round(floatval($item->total_duration_seconds ?? 0) / 60, 2),
                round(floatval($item->avg_duration_seconds ?? 0) / 60, 2),
            ];
        })->values()->toArray();

        return $this->dataTableFromRows($request, $rows);
    }

    public function listUserGrowthQualityReport(Request $request)
    {
        [$startDate, $endDate] = $this->resolveDateRange($request);

        $createdRows = Users::whereBetween('created_at', [$startDate, $endDate])
            ->select(
                DB::raw('DATE(created_at) as report_date'),
                DB::raw('COUNT(*) as total_users'),
                DB::raw('SUM(CASE WHEN is_dummy = 0 THEN 1 ELSE 0 END) as real_users'),
                DB::raw('SUM(CASE WHEN is_dummy = 1 THEN 1 ELSE 0 END) as dummy_users'),
                DB::raw('SUM(CASE WHEN is_verify = 1 THEN 1 ELSE 0 END) as verified_users')
            )
            ->groupBy(DB::raw('DATE(created_at)'))
            ->orderBy(DB::raw('DATE(created_at)'), 'DESC')
            ->get();

        $activeByDate = Users::whereNotNull('app_last_used_at')
            ->whereBetween('app_last_used_at', [$startDate, $endDate])
            ->select(DB::raw('DATE(app_last_used_at) as d'), DB::raw('COUNT(DISTINCT id) as active_users'))
            ->groupBy(DB::raw('DATE(app_last_used_at)'))
            ->pluck('active_users', 'd');

        $rows = $createdRows->map(function ($item) use ($activeByDate) {
            $date = (string) $item->report_date;
            $total = intval($item->total_users ?? 0);
            $verified = intval($item->verified_users ?? 0);
            $verifiedPercent = $total > 0 ? round(($verified * 100) / $total, 2) : 0;

            return [
                $date,
                $total,
                intval($item->real_users ?? 0),
                intval($item->dummy_users ?? 0),
                $verified,
                $verifiedPercent . '%',
                intval($activeByDate[$date] ?? 0),
            ];
        })->values()->toArray();

        return $this->dataTableFromRows($request, $rows);
    }

    public function listGiftAnalyticsReport(Request $request)
    {
        [$startDate, $endDate] = $this->resolveDateRange($request);

        $items = DB::table('notification_users as n')
            ->join('tbl_gifts as g', 'g.id', '=', 'n.data_id')
            ->leftJoin('tbl_gift_categories as gc', 'gc.id', '=', 'g.gift_category_id')
            ->where('n.type', Constants::notify_gift_user)
            ->whereBetween('n.created_at', [$startDate, $endDate])
            ->select(
                DB::raw("COALESCE(NULLIF(TRIM(gc.name), ''), 'Uncategorized') as category_name"),
                DB::raw("COALESCE(NULLIF(TRIM(n.source), ''), 'unknown') as source_name"),
                DB::raw('COUNT(*) as gifts_count'),
                DB::raw('SUM(g.coin_price) as total_diamonds'),
                DB::raw('COUNT(DISTINCT n.from_user_id) as unique_senders'),
                DB::raw('COUNT(DISTINCT n.to_user_id) as unique_receivers')
            )
            ->groupBy(DB::raw("COALESCE(NULLIF(TRIM(gc.name), ''), 'Uncategorized')"), DB::raw("COALESCE(NULLIF(TRIM(n.source), ''), 'unknown')"))
            ->orderByDesc('total_diamonds')
            ->get();

        $rows = $items->map(function ($item) {
            return [
                e((string) $item->category_name),
                e((string) $item->source_name),
                intval($item->gifts_count ?? 0),
                GlobalFunction::formatNumber($item->total_diamonds ?? 0),
                intval($item->unique_senders ?? 0),
                intval($item->unique_receivers ?? 0),
            ];
        })->values()->toArray();

        return $this->dataTableFromRows($request, $rows);
    }

    public function listAgentStatePerformanceReport(Request $request)
    {
        [$startDate, $endDate] = $this->resolveDateRange($request);

        $agents = Users::where('is_agent', 1)
            ->where('is_dummy', 0)
            ->select('id', 'username', 'fullname')
            ->orderBy('id', 'DESC')
            ->get();

        $stateAgentIdMap = StateMaster::whereNotNull('agent_id')
            ->where('agent_id', '>', 0)
            ->pluck('agent_id')
            ->map(fn($id) => intval($id))
            ->flip();

        $referralsMap = Users::whereNotNull('agent_id')
            ->where('is_dummy', 0)
            ->select('agent_id', DB::raw('COUNT(*) as total_referrals'))
            ->groupBy('agent_id')
            ->pluck('total_referrals', 'agent_id');

        $activeReferralsMap = Users::whereNotNull('agent_id')
            ->where('is_dummy', 0)
            ->whereNotNull('app_last_used_at')
            ->whereBetween('app_last_used_at', [$startDate, $endDate])
            ->select('agent_id', DB::raw('COUNT(*) as active_referrals'))
            ->groupBy('agent_id')
            ->pluck('active_referrals', 'agent_id');

        $commissionMap = AgentCommissionEntries::whereBetween('created_at', [$startDate, $endDate])
            ->select('agent_id', DB::raw('COUNT(*) as entries_count'), DB::raw('SUM(commission_amount) as total_commission'))
            ->groupBy('agent_id')
            ->get()
            ->mapWithKeys(function ($item) {
                return [intval($item->agent_id) => [
                    'entries_count' => intval($item->entries_count ?? 0),
                    'total_commission' => floatval($item->total_commission ?? 0),
                ]];
            });

        $rows = $agents->map(function ($agent) use ($stateAgentIdMap, $referralsMap, $activeReferralsMap, $commissionMap) {
            $agentId = intval($agent->id);
            $stats = $commissionMap[$agentId] ?? ['entries_count' => 0, 'total_commission' => 0];
            $name = e(trim((string) ($agent->fullname ?: $agent->username ?: ('Agent ' . $agentId)))) . " ({$agentId})";
            return [
                $name,
                isset($stateAgentIdMap[$agentId]) ? 'Yes' : 'No',
                intval($referralsMap[$agentId] ?? 0),
                intval($activeReferralsMap[$agentId] ?? 0),
                intval($stats['entries_count'] ?? 0),
                GlobalFunction::formatNumber($stats['total_commission'] ?? 0),
            ];
        })->values()->toArray();

        return $this->dataTableFromRows($request, $rows);
    }

    public function listModerationRiskReport(Request $request)
    {
        [$startDate, $endDate] = $this->resolveDateRange($request);

        $userReports = ReportUsers::whereBetween('created_at', [$startDate, $endDate])
            ->select('user_id', DB::raw('COUNT(*) as user_reports'))
            ->groupBy('user_id')
            ->pluck('user_reports', 'user_id');

        $postReports = ReportPosts::whereBetween('created_at', [$startDate, $endDate])
            ->join('tbl_post as p', 'p.id', '=', 'report_posts.post_id')
            ->select('p.user_id', DB::raw('COUNT(*) as post_reports'))
            ->groupBy('p.user_id')
            ->pluck('post_reports', 'p.user_id');

        $userIds = collect(array_merge(
            array_keys($userReports->toArray()),
            array_keys($postReports->toArray())
        ))->unique()->values();

        $users = $userIds->isEmpty()
            ? collect()
            : Users::whereIn('id', $userIds->toArray())->get()->keyBy('id');

        $rows = $userIds->map(function ($id) use ($userReports, $postReports, $users) {
            $item = $users->get($id);
            $userName = $item
                ? e(trim((string) ($item->fullname ?: $item->username ?: ('User ' . $item->id)))) . " ({$item->id})"
                : ("User ({$id})");

            $uCount = intval($userReports[$id] ?? 0);
            $pCount = intval($postReports[$id] ?? 0);
            $total = $uCount + $pCount;
            $freezeStatus = $item ? (intval($item->is_freez ?? 0) === 1 ? 'Frozen' : 'Active') : '-';

            return [
                $userName,
                $uCount,
                $pCount,
                $total,
                $freezeStatus,
            ];
        })->sortByDesc(function ($row) {
            return intval($row[3] ?? 0);
        })->values()->toArray();

        return $this->dataTableFromRows($request, $rows);
    }
    //
    public function reportPost(Request $request){
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if ($user->is_freez == 1) {
            return ['status' => false, 'message' => "this user is freezed!"];
        }

        $rules = [
            'post_id' =>'required|exists:tbl_post,id',
            'reason' =>'required',
            'description' =>'required',
        ];

        $validator = Validator::make($request->all(), $rules);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->all()]);
        }

       $report = ReportPosts::where([
        'post_id'=> $request->post_id,
        'by_user_id'=> $user->id,
       ])->first();
       if($report != null){
        return GlobalFunction::sendSimpleResponse(false,'you have reported this post already!');
       }
       $report = new ReportPosts();
       $report->post_id = $request->post_id;
       $report->by_user_id = $user->id;
       $report->reason = $request->reason;
       $report->description = $request->description;
       $report->save();

    return GlobalFunction::sendSimpleResponse(true, 'post report submitted successfully');

    }
}
