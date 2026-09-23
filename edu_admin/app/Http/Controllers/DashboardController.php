<?php

namespace App\Http\Controllers;

use App\Models\Constants;
use App\Models\DailyActiveUsers;
use App\Models\GlobalFunction;
use App\Models\GlobalSettings;
use App\Models\Posts;
use App\Models\RedeemRequests;
use App\Models\ReportPosts;
use App\Models\ReportUsers;
use App\Models\Users;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;

class DashboardController extends Controller
{
    private const LIVE_WINDOW_MINUTES = 5;

    private function calculateGrowth(float|int $current, float|int $previous): float
    {
        if ($previous <= 0) {
            return $current > 0 ? 100.0 : 0.0;
        }

        return (($current - $previous) / $previous) * 100;
    }

    private function formatGrowth(float $growth): string
    {
        return number_format($growth, 1);
    }

    //
    function dashboard()
    {
        // Validate googleCredentials.json file
        try {
            $filePath = base_path('googleCredentials.json');
            if (!File::exists($filePath)) {
                return response()->json(['message' => 'The googleCredentials.json file does not exist.'], 404);
            }

            $contents = File::get($filePath);
            if (empty(trim($contents))) {
                return response()->view('google_credentials_empty');
            }

            // Validate JSON format
            $json = json_decode($contents, true);
            if (json_last_error() !== JSON_ERROR_NONE) {
                return response()->json(['message' => 'The googleCredentials.json file contains invalid JSON.'], 400);
            }

        } catch (\Exception $e) {
            return response()->json(['message' => 'An error occurred: ' . $e->getMessage()], 500);
        }

        $userTotal = Users::count();
        $userFreezed = Users::where('is_freez', 1)->count();
        $userModerator = Users::where('is_moderator', 1)->count();
        $userDummy = Users::where('is_dummy', 1)->count();

        $postsTotal = Posts::count();
        $postsReels = Posts::where('post_type', Constants::postTypeReel)->count();
        $postsVideos = Posts::where('post_type', Constants::postTypeVideo)->count();
        $postsImages = Posts::where('post_type', Constants::postTypeImage)->count();
        $postsText = Posts::where('post_type', Constants::postTypeText)->count();

        $reportsPost = ReportPosts::count();
        $reportsUser = ReportUsers::count();

        $withdrawalPending = RedeemRequests::where('status', Constants::withdrawalPending)->count();
        $withdrawalCompleted = RedeemRequests::where('status', Constants::withdrawalCompleted)->count();
        $withdrawalRejected = RedeemRequests::where('status', Constants::withdrawalRejected)->count();

        $settings = GlobalSettings::first();
        $minFollowersForHost = $settings?->min_followers_for_live ?? 0;
        $coinValue = (float) ($settings?->coin_value ?? 0);
        $currency = $settings?->currency ?? '$';

        $totalHosts = Users::where('follower_count', '>=', $minFollowersForHost)->count();

        $liveThreshold = Carbon::now()->subMinutes(self::LIVE_WINDOW_MINUTES);
        $liveUsersRealtime = Users::where('app_last_used_at', '>=', $liveThreshold)->count();
        $ongoingLiveSessions = Users::where('follower_count', '>=', $minFollowersForHost)
            ->where('app_last_used_at', '>=', $liveThreshold)
            ->count();

        $totalDiamondsPurchased = (int) Users::sum('coin_purchased_lifetime');
        $totalStarsEarned = (int) Users::sum('coin_collected_lifetime');
        $totalRevenue = $totalDiamondsPurchased * $coinValue;

        $todayNewUsers = Users::whereDate('created_at', Carbon::today())->count();
        $yesterdayNewUsers = Users::whereDate('created_at', Carbon::yesterday())->count();
        $todayGrowthPercent = $this->calculateGrowth($todayNewUsers, $yesterdayNewUsers);

        $weekStart = Carbon::now()->startOfWeek();
        $weekEnd = Carbon::now()->endOfWeek();
        $lastWeekStart = Carbon::now()->subWeek()->startOfWeek();
        $lastWeekEnd = Carbon::now()->subWeek()->endOfWeek();
        $weeklyNewUsers = Users::whereBetween('created_at', [$weekStart, $weekEnd])->count();
        $lastWeeklyNewUsers = Users::whereBetween('created_at', [$lastWeekStart, $lastWeekEnd])->count();
        $weeklyGrowthPercent = $this->calculateGrowth($weeklyNewUsers, $lastWeeklyNewUsers);

        $monthStart = Carbon::now()->startOfMonth();
        $monthEnd = Carbon::now()->endOfMonth();
        $lastMonthStart = Carbon::now()->subMonthNoOverflow()->startOfMonth();
        $lastMonthEnd = Carbon::now()->subMonthNoOverflow()->endOfMonth();
        $monthlyNewUsers = Users::whereBetween('created_at', [$monthStart, $monthEnd])->count();
        $lastMonthlyNewUsers = Users::whereBetween('created_at', [$lastMonthStart, $lastMonthEnd])->count();
        $monthlyGrowthPercent = $this->calculateGrowth($monthlyNewUsers, $lastMonthlyNewUsers);

        return view('dashboard')->with([
            'userTotal'=> $userTotal,
            'userFreezed'=> $userFreezed,
            'userModerator'=> $userModerator,
            'userDummy'=> $userDummy,

            'postsTotal'=> $postsTotal,
            'postsReels'=> $postsReels,
            'postsVideos'=> $postsVideos,
            'postsImages'=> $postsImages,
            'postsText'=> $postsText,

            'reportsPost'=> $reportsPost,
            'reportsUser'=> $reportsUser,

            'withdrawalPending'=> $withdrawalPending,
            'withdrawalCompleted'=> $withdrawalCompleted,
            'withdrawalRejected'=> $withdrawalRejected,

            'totalHosts' => $totalHosts,
            'liveUsersRealtime' => $liveUsersRealtime,
            'ongoingLiveSessions' => $ongoingLiveSessions,
            'liveWindowMinutes' => self::LIVE_WINDOW_MINUTES,
            'totalDiamondsPurchased' => $totalDiamondsPurchased,
            'totalStarsEarned' => $totalStarsEarned,
            'totalRevenue' => $totalRevenue,
            'currency' => $currency,
            'todayNewUsers' => $todayNewUsers,
            'weeklyNewUsers' => $weeklyNewUsers,
            'monthlyNewUsers' => $monthlyNewUsers,
            'todayGrowthPercent' => $this->formatGrowth($todayGrowthPercent),
            'weeklyGrowthPercent' => $this->formatGrowth($weeklyGrowthPercent),
            'monthlyGrowthPercent' => $this->formatGrowth($monthlyGrowthPercent),
        ]);


    }

    function fetchChartData(Request $request){

            $month = $request->month;
            $year = $request->year;

            // Log::debug($month . $year);

            $startDate = Carbon::create($year, $month, 1);
            $endDate = Carbon::create($year, $month, 1)->endOfMonth();
            $dates = collect();

            $datesWithCount = [];
            for ($date = $startDate; $date->lte($endDate); $date->addDay()) {
                $formattedDate = $date->format('Y-m-d');
                $dates->push($formattedDate);

                $usersCount = Users::whereDate('created_at', $date)->count();
                $postsCount = Posts::whereDate('created_at', $date)->count();

                $dauCount = 0;

                if ($date->isToday()) {
                    // If it's today, get users active today from app_last_used_at
                    $dauCount = Users::whereDate('app_last_used_at', $date)->count();
                } else {
                    // Otherwise, get from daily_active_users table
                    $dau = DailyActiveUsers::whereDate('date', $date)->first();
                    $dauCount = $dau?->user_count ?? 0;
                }

                $datesWithCount[] = [
                    'date' => $formattedDate,
                    'usersCount' => $usersCount,
                    'postsCount' => $postsCount,
                    'dauCount' => $dauCount,
                ];
            }
            return GlobalFunction::sendDataResponse(true, 'Users fetched successfully.', $datesWithCount);
    }
}
