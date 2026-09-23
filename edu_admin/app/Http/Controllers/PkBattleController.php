<?php

namespace App\Http\Controllers;

use App\Models\GlobalFunction;
use App\Models\PkBattleHistory;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Validator;

class PkBattleController extends Controller
{
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

    public function saveBattleResult(Request $request)
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
            'mode' => 'required|in:video,audio',
            'user1_id' => 'required|exists:tbl_users,id',
            'user2_id' => 'required|exists:tbl_users,id|different:user1_id',
            'user1_coins' => 'required|integer|min:0',
            'user2_coins' => 'required|integer|min:0',
            'duration_minutes' => 'nullable|integer|min:0',
            'started_at' => 'nullable|date',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $user1Id = intval($request->user1_id);
        $user2Id = intval($request->user2_id);
        if (intval($user->id) !== $user1Id && intval($user->id) !== $user2Id) {
            return GlobalFunction::sendSimpleResponse(false, 'Only a battle participant can save the result');
        }

        $endedAt = Carbon::now();
        $startedAt = $request->filled('started_at')
            ? Carbon::parse($request->started_at)
            : $endedAt->copy()->subMinutes(intval($request->duration_minutes ?? 0));

        // Both hosts call this when the timer ends, so drop the second write
        // instead of creating a duplicate row for the same battle.
        $existing = PkBattleHistory::whereIn('user1_id', [$user1Id, $user2Id])
            ->whereIn('user2_id', [$user1Id, $user2Id])
            ->where('ended_at', '>=', $endedAt->copy()->subMinutes(2))
            ->first();
        if ($existing) {
            return GlobalFunction::sendDataResponse(true, 'Battle result already saved', [
                'id' => intval($existing->id),
                'winner_id' => $existing->winner_id !== null ? intval($existing->winner_id) : null,
            ]);
        }

        $user1Coins = intval($request->user1_coins);
        $user2Coins = intval($request->user2_coins);

        $winnerId = null;
        if ($user1Coins > $user2Coins) {
            $winnerId = $user1Id;
        } elseif ($user2Coins > $user1Coins) {
            $winnerId = $user2Id;
        }

        $battle = new PkBattleHistory();
        $battle->mode = $request->mode;
        $battle->user1_id = $user1Id;
        $battle->user2_id = $user2Id;
        $battle->user1_coins = $user1Coins;
        $battle->user2_coins = $user2Coins;
        $battle->winner_id = $winnerId;
        $battle->duration_minutes = intval($request->duration_minutes ?? 0);
        $battle->started_at = $startedAt;
        $battle->ended_at = $endedAt;
        $battle->save();

        return GlobalFunction::sendDataResponse(true, 'Battle result saved', [
            'id' => intval($battle->id),
            'winner_id' => $winnerId,
            'user1_coins' => $user1Coins,
            'user2_coins' => $user2Coins,
        ]);
    }

    public function fetchTopPkBattlePlayers(Request $request)
    {
        $token = $request->header('authtoken');
        $me = GlobalFunction::getUserFromAuthToken($token);
        if (!$me) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }

        $validator = Validator::make($request->all(), [
            'period' => 'nullable|in:today,yesterday,this_week,this_month,all_time',
            'mode' => 'nullable|in:video,audio',
            'limit' => 'nullable|integer|min:1|max:100',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $limit = intval($request->limit ?? 20);
        [$start, $end] = $this->resolvePeriodRange($request->period ?? 'today');
        $mode = $request->mode;

        $modeSql = !empty($mode) ? ' AND mode = ?' : '';
        $sideParams = !empty($mode) ? [$start, $end, $mode] : [$start, $end];
        $params = array_merge($sideParams, $sideParams);

        // Each battle row holds two players, so unfold both sides before
        // aggregating wins and coins per user.
        $sql = "
            SELECT u.id, u.username, u.fullname, u.profile_photo, ul.level as user_level,
                   COUNT(*) as battles,
                   SUM(CASE WHEN sides.winner_id = sides.player_id THEN 1 ELSE 0 END) as wins,
                   SUM(sides.coins) as total_coins
            FROM (
                SELECT user1_id AS player_id, user1_coins AS coins, winner_id
                    FROM tbl_pk_battle_history WHERE ended_at BETWEEN ? AND ?{$modeSql}
                UNION ALL
                SELECT user2_id AS player_id, user2_coins AS coins, winner_id
                    FROM tbl_pk_battle_history WHERE ended_at BETWEEN ? AND ?{$modeSql}
            ) as sides
            JOIN tbl_users as u ON u.id = sides.player_id
            LEFT JOIN user_levels as ul ON ul.id = u.level_id
            GROUP BY u.id, u.username, u.fullname, u.profile_photo, ul.level
            ORDER BY wins DESC, total_coins DESC
        ";
        $rows = collect(DB::select($sql, $params));

        $followingIds = DB::table('tbl_followers')
            ->where('from_user_id', $me->id)
            ->pluck('to_user_id')
            ->map(fn($id) => intval($id))
            ->all();

        $ranked = $rows->map(function ($item, $index) use ($followingIds) {
            return [
                'rank' => $index + 1,
                'user_id' => intval($item->id),
                'username' => $item->username,
                'fullname' => $item->fullname,
                'profile_photo' => !empty($item->profile_photo) ? GlobalFunction::generateFileUrl($item->profile_photo) : null,
                'user_level' => intval($item->user_level ?? 0),
                'battles' => intval($item->battles),
                'wins' => intval($item->wins),
                'total_stars' => intval($item->total_coins),
                'is_following' => in_array(intval($item->id), $followingIds, true),
            ];
        });

        $myRank = $ranked->firstWhere('user_id', intval($me->id));

        return response()->json([
            'status' => true,
            'message' => 'Top PK battle players fetched successfully',
            'data' => $ranked->take($limit)->values(),
            'my_rank' => $myRank,
        ]);
    }
}
