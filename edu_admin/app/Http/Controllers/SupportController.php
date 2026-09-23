<?php

namespace App\Http\Controllers;

use App\Models\GlobalFunction;
use App\Models\UserSupport;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Validator;

class SupportController extends Controller
{
    public function supports()
    {
        return view('supports');
    }

    public function createSupport(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if (intval($user->is_freez ?? 0) === 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'subject' => 'required|string|max:255',
            'message' => 'required|string|max:5000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $support = new UserSupport();
        $support->user_id = intval($user->id);
        $support->subject = trim((string) $request->subject);
        $support->message = trim((string) $request->message);
        $support->status = UserSupport::STATUS_OPEN;
        $support->save();

        return GlobalFunction::sendDataResponse(true, 'Support request created successfully', [
            'id' => intval($support->id),
            'subject' => (string) $support->subject,
            'message' => (string) $support->message,
            'status' => (string) $support->status,
            'admin_reply' => $support->admin_reply,
            'admin_name' => $support->admin_name,
            'created_at' => Carbon::parse($support->created_at)->format('Y-m-d H:i:s'),
            'updated_at' => Carbon::parse($support->updated_at)->format('Y-m-d H:i:s'),
        ]);
    }

    public function fetchMySupports(Request $request)
    {
        $token = $request->header('authtoken');
        $user = GlobalFunction::getUserFromAuthToken($token);
        if (!$user) {
            return GlobalFunction::sendSimpleResponse(false, 'User not found!');
        }
        if (intval($user->is_freez ?? 0) === 1) {
            return ['status' => false, 'message' => 'this user is freezed!'];
        }

        $validator = Validator::make($request->all(), [
            'limit' => 'required|integer|min:1|max:100',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $query = UserSupport::where('user_id', intval($user->id))
            ->orderBy('id', 'DESC')
            ->limit(intval($request->limit));

        if ($request->filled('last_item_id')) {
            $query->where('id', '<', intval($request->last_item_id));
        }

        $items = $query->get()->map(function ($item) {
            return [
                'id' => intval($item->id),
                'subject' => (string) ($item->subject ?? ''),
                'message' => (string) ($item->message ?? ''),
                'status' => (string) ($item->status ?? UserSupport::STATUS_OPEN),
                'admin_reply' => $item->admin_reply,
                'admin_name' => $item->admin_name,
                'replied_at' => !empty($item->replied_at) ? Carbon::parse($item->replied_at)->format('Y-m-d H:i:s') : null,
                'closed_at' => !empty($item->closed_at) ? Carbon::parse($item->closed_at)->format('Y-m-d H:i:s') : null,
                'created_at' => !empty($item->created_at) ? Carbon::parse($item->created_at)->format('Y-m-d H:i:s') : null,
                'updated_at' => !empty($item->updated_at) ? Carbon::parse($item->updated_at)->format('Y-m-d H:i:s') : null,
            ];
        })->values();

        return GlobalFunction::sendDataResponse(true, 'Support requests fetched successfully', $items);
    }

    public function listSupports(Request $request)
    {
        $query = UserSupport::with('user:id,username,fullname');
        $totalData = $query->count();

        $limit = intval($request->input('length'));
        $start = intval($request->input('start'));
        $searchValue = trim((string) $request->input('search.value'));
        $status = trim((string) $request->input('status'));

        if ($status !== '' && in_array($status, [UserSupport::STATUS_OPEN, UserSupport::STATUS_ANSWERED, UserSupport::STATUS_CLOSED], true)) {
            $query->where('status', $status);
        }

        if ($searchValue !== '') {
            $query->where(function ($q) use ($searchValue) {
                $q->where('subject', 'LIKE', "%{$searchValue}%")
                    ->orWhere('message', 'LIKE', "%{$searchValue}%")
                    ->orWhere('admin_reply', 'LIKE', "%{$searchValue}%")
                    ->orWhereHas('user', function ($userQuery) use ($searchValue) {
                        $userQuery->where('username', 'LIKE', "%{$searchValue}%")
                            ->orWhere('fullname', 'LIKE', "%{$searchValue}%")
                            ->orWhere('id', 'LIKE', "%{$searchValue}%");
                    });
            });
        }
        $totalFiltered = $query->count();

        $rows = $query->offset($start)->limit($limit)->orderBy('id', 'DESC')->get();

        $data = $rows->map(function ($item) {
            $userLabel = $item->user
                ? ('#' . intval($item->user->id) . ' | ' . e($item->user->fullname ?: $item->user->username ?: 'User'))
                : ('#' . intval($item->user_id));

            $details = "<div class='reportDescription'>"
                . "<h5 class='mb-1'>" . e($item->subject ?? '-') . "</h5>"
                . "<p class='mb-1'>" . nl2br(e($item->message ?? '-')) . "</p>";

            if (!empty($item->admin_reply)) {
                $replyBy = trim((string) ($item->admin_name ?? 'Admin'));
                $details .= "<p class='mb-0 text-muted'><strong>Reply ({$replyBy}):</strong> " . nl2br(e($item->admin_reply)) . "</p>";
            }

            $details .= "</div>";

            $statusClass = match ($item->status) {
                UserSupport::STATUS_ANSWERED => 'bg-success',
                UserSupport::STATUS_CLOSED => 'bg-secondary',
                default => 'bg-warning',
            };
            $status = "<span class='badge {$statusClass}'>" . e(ucfirst((string) $item->status)) . "</span>";

            $reply = "<a href='#'
                        rel='{$item->id}'
                        data-subject='" . e($item->subject ?? '') . "'
                        data-message='" . e($item->message ?? '') . "'
                        data-reply='" . e($item->admin_reply ?? '') . "'
                        class='action-btn reply d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-comment-message'></i>
                        </a>";

            $close = "<a href='#'
                        rel='{$item->id}'
                        class='action-btn close-ticket d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                        <i class='uil-times-circle'></i>
                        </a>";

            $reopen = "<a href='#'
                        rel='{$item->id}'
                        class='action-btn reopen-ticket d-flex align-items-center justify-content-center btn border rounded-2 text-info ms-1'>
                        <i class='uil-redo'></i>
                        </a>";

            $actions = $item->status === UserSupport::STATUS_CLOSED
                ? "<span class='d-flex justify-content-end align-items-center'>{$reply}{$reopen}</span>"
                : "<span class='d-flex justify-content-end align-items-center'>{$reply}{$close}</span>";

            return [
                $userLabel,
                $details,
                $status,
                GlobalFunction::formateDatabaseTime($item->created_at),
                $actions,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function replySupport(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:user_supports,id',
            'admin_reply' => 'required|string|max:5000',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $support = UserSupport::find(intval($request->id));
        $support->admin_reply = trim((string) $request->admin_reply);
        $support->admin_name = trim((string) session('username', 'Admin'));
        $support->status = UserSupport::STATUS_ANSWERED;
        $support->replied_at = Carbon::now();
        $support->save();

        return GlobalFunction::sendSimpleResponse(true, 'Support reply saved successfully');
    }

    public function closeSupport(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:user_supports,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $support = UserSupport::find(intval($request->id));
        $support->status = UserSupport::STATUS_CLOSED;
        $support->closed_at = Carbon::now();
        $support->save();

        return GlobalFunction::sendSimpleResponse(true, 'Support ticket closed successfully');
    }

    public function reopenSupport(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:user_supports,id',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $support = UserSupport::find(intval($request->id));
        $support->status = UserSupport::STATUS_OPEN;
        $support->closed_at = null;
        $support->save();

        return GlobalFunction::sendSimpleResponse(true, 'Support ticket reopened successfully');
    }
}
