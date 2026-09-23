<?php

namespace App\Http\Controllers;

use App\Models\AudioRoomHistory;
use App\Models\GlobalFunction;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Validator;

class AudioRoomController extends Controller
{
    public function startAudioRoom(Request $request)
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
            return GlobalFunction::sendSimpleResponse(false, 'Only approved host can start an audio room');
        }

        $validator = Validator::make($request->all(), [
            'room_id' => 'required|string|max:191',
            'room_name' => 'nullable|string|max:255',
            'language_id' => 'nullable|exists:languages,id',
            'force' => 'nullable|in:0,1',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $activeRoom = AudioRoomHistory::where('host_id', $user->id)->where('status', 1)->first();
        if ($activeRoom) {
            if (intval($request->force ?? 0) !== 1) {
                return GlobalFunction::sendDataResponse(false, 'Audio room already running', [
                    'audio_room_id' => intval($activeRoom->id),
                    'started_at' => !empty($activeRoom->started_at) ? Carbon::parse($activeRoom->started_at)->format('Y-m-d H:i:s') : null,
                ]);
            }

            $endedAt = Carbon::now();
            $startedAt = !empty($activeRoom->started_at) ? Carbon::parse($activeRoom->started_at) : $endedAt;
            $activeRoom->ended_at = $endedAt;
            $activeRoom->duration = max(0, $startedAt->diffInSeconds($endedAt));
            $activeRoom->status = 0;
            $activeRoom->save();
        }

        $room = new AudioRoomHistory();
        $room->host_id = $user->id;
        $room->room_id = $request->room_id;
        $room->room_name = $request->room_name;
        $room->language_id = $request->language_id;
        $room->started_at = Carbon::now();
        $room->status = 1;
        $room->save();

        return GlobalFunction::sendDataResponse(true, 'Audio room started', [
            'id' => intval($room->id),
            'room_id' => $room->room_id,
            'started_at' => Carbon::parse($room->started_at)->format('Y-m-d H:i:s'),
        ]);
    }

    public function endAudioRoom(Request $request)
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
            'audio_room_id' => 'required|exists:tbl_audio_room_history,id',
            'peak_listener_count' => 'nullable|integer|min:0',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $room = AudioRoomHistory::find($request->audio_room_id);
        if (!$room || intval($room->host_id) !== intval($user->id)) {
            return GlobalFunction::sendSimpleResponse(false, 'Audio room not found');
        }
        if (intval($room->status) !== 1) {
            return GlobalFunction::sendSimpleResponse(false, 'Audio room already ended');
        }

        $endedAt = Carbon::now();
        $startedAt = Carbon::parse($room->started_at);

        $room->ended_at = $endedAt;
        $room->duration = max(0, $startedAt->diffInSeconds($endedAt));
        if ($request->filled('peak_listener_count')) {
            $room->peak_listener_count = intval($request->peak_listener_count);
        }
        $room->status = 0;
        $room->save();

        return GlobalFunction::sendDataResponse(true, 'Audio room ended', [
            'id' => intval($room->id),
            'duration' => intval($room->duration),
            'peak_listener_count' => intval($room->peak_listener_count),
            'started_at' => $startedAt->format('Y-m-d H:i:s'),
            'ended_at' => Carbon::parse($room->ended_at)->format('Y-m-d H:i:s'),
        ]);
    }
}
