<?php

namespace App\Http\Controllers;

use App\Models\Coupons;
use App\Models\GlobalFunction;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Validator;
use Illuminate\Validation\Rule;

class CouponController extends Controller
{
    public function fetchCoupons(Request $request)
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
            'limit' => 'nullable|integer|min:1|max:100',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $limit = intval($request->limit ?? 20);
        $today = Carbon::today()->toDateString();

        $items = Coupons::query()
            ->where('status', 1)
            ->where(function ($q) use ($today) {
                $q->whereNull('end_date')->orWhere('end_date', '>=', $today);
            })
            ->where(function ($q) {
                $q->whereNull('max_users')->orWhereColumn('used_users', '<', 'max_users');
            })
            ->orderBy('id', 'DESC')
            ->limit($limit)
            ->get()
            ->map(function ($item) {
                return [
                    'id' => intval($item->id),
                    'code' => $item->coupon_code,
                    'type' => $item->discount_type,
                    'value' => floatval($item->discount_value),
                    'expiry_date' => $item->end_date,
                    'max_uses' => !is_null($item->max_users) ? intval($item->max_users) : null,
                    'used_count' => intval($item->used_users ?? 0),
                    'is_active' => intval($item->status),
                ];
            })
            ->values();

        return GlobalFunction::sendDataResponse(true, 'Coupons fetched successfully', $items);
    }

    public function coupons()
    {
        return view('coupons');
    }

    public function listCoupons(Request $request)
    {
        $query = Coupons::query();
        $totalData = $query->count();

        $limit = $request->input('length');
        $start = $request->input('start');
        $searchValue = $request->input('search.value');

        if (!empty($searchValue)) {
            $query->where(function ($q) use ($searchValue) {
                $q->where('coupon_code', 'LIKE', "%{$searchValue}%")
                    ->orWhere('discount_type', 'LIKE', "%{$searchValue}%")
                    ->orWhere('discount_value', 'LIKE', "%{$searchValue}%");
            });
        }

        $totalFiltered = $query->count();

        $result = $query->offset($start)
            ->limit($limit)
            ->orderBy('id', 'DESC')
            ->get();

        $data = $result->map(function ($item) {
            $discountLabel = $item->discount_type === 'percentage'
                ? ($item->discount_value . '%')
                : $item->discount_value;

            $endDateLabel = !empty($item->end_date)
                ? Carbon::parse($item->end_date)->format('Y-m-d')
                : 'Unlimited';

            $usersLimitLabel = !empty($item->max_users)
                ? intval($item->max_users)
                : 'Unlimited';

            $edit = "<a href='#'
                        rel='{$item->id}'
                        data-couponcode='{$item->coupon_code}'
                        data-discounttype='{$item->discount_type}'
                        data-discountvalue='{$item->discount_value}'
                        data-enddate='{$item->end_date}'
                        data-maxusers='{$item->max_users}'
                        class='action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1'>
                        <i class='uil-pen'></i>
                        </a>";

            $delete = "<a href='#'
                          rel='{$item->id}'
                          class='action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1'>
                            <i class='uil-trash-alt'></i>
                        </a>";
            $action = "<span class='d-flex justify-content-end align-items-center'>{$edit}{$delete}</span>";

            $checked = intval($item->status) === 1 ? 'checked' : '';
            $status = "<input type='checkbox' id='couponStatus-{$item->id}' rel='{$item->id}' class='onOffCoupon' {$checked} data-switch='none'/>
                    <label for='couponStatus-{$item->id}'></label>";

            return [
                $item->coupon_code,
                ucfirst($item->discount_type),
                $discountLabel,
                $endDateLabel,
                $usersLimitLabel,
                intval($item->used_users ?? 0),
                $status,
                $action,
            ];
        });

        return response()->json([
            'draw' => intval($request->input('draw')),
            'recordsTotal' => intval($totalData),
            'recordsFiltered' => intval($totalFiltered),
            'data' => $data,
        ]);
    }

    public function addCoupon(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'coupon_code' => 'required|string|max:100|unique:tbl_coupons,coupon_code',
            'discount_type' => 'required|in:percentage,amount',
            'discount_value' => 'required|numeric|min:0',
            'end_date' => 'nullable|date',
            'max_users' => 'nullable|integer|min:1',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $isUnlimitedEndDate = intval($request->unlimited_end_date ?? 0) === 1;
        $isUnlimitedUsers = intval($request->unlimited_users ?? 0) === 1;

        if (!$isUnlimitedEndDate && empty($request->end_date)) {
            return GlobalFunction::sendSimpleResponse(false, 'End date is required when not unlimited');
        }
        if (!$isUnlimitedUsers && empty($request->max_users)) {
            return GlobalFunction::sendSimpleResponse(false, 'No. of users is required when not unlimited');
        }

        $item = new Coupons();
        $item->coupon_code = strtoupper(trim($request->coupon_code));
        $item->discount_type = $request->discount_type;
        $item->discount_value = $request->discount_value;
        $item->end_date = $isUnlimitedEndDate ? null : $request->end_date;
        $item->max_users = $isUnlimitedUsers ? null : intval($request->max_users);
        $item->used_users = 0;
        $item->status = 1;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Coupon added successfully');
    }

    public function editCoupon(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'id' => 'required|exists:tbl_coupons,id',
            'coupon_code' => [
                'required',
                'string',
                'max:100',
                Rule::unique('tbl_coupons', 'coupon_code')->ignore($request->id),
            ],
            'discount_type' => 'required|in:percentage,amount',
            'discount_value' => 'required|numeric|min:0',
            'end_date' => 'nullable|date',
            'max_users' => 'nullable|integer|min:1',
        ]);
        if ($validator->fails()) {
            return response()->json(['status' => false, 'message' => $validator->errors()->first()]);
        }

        $item = Coupons::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Coupon not found');
        }

        $isUnlimitedEndDate = intval($request->unlimited_end_date ?? 0) === 1;
        $isUnlimitedUsers = intval($request->unlimited_users ?? 0) === 1;

        if (!$isUnlimitedEndDate && empty($request->end_date)) {
            return GlobalFunction::sendSimpleResponse(false, 'End date is required when not unlimited');
        }
        if (!$isUnlimitedUsers && empty($request->max_users)) {
            return GlobalFunction::sendSimpleResponse(false, 'No. of users is required when not unlimited');
        }

        $item->coupon_code = strtoupper(trim($request->coupon_code));
        $item->discount_type = $request->discount_type;
        $item->discount_value = $request->discount_value;
        $item->end_date = $isUnlimitedEndDate ? null : $request->end_date;
        $item->max_users = $isUnlimitedUsers ? null : intval($request->max_users);
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Coupon edited successfully');
    }

    public function deleteCoupon(Request $request)
    {
        $item = Coupons::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Coupon not found');
        }
        $item->delete();

        return GlobalFunction::sendSimpleResponse(true, 'Coupon deleted successfully');
    }

    public function changeCouponStatus(Request $request)
    {
        $item = Coupons::find($request->id);
        if (!$item) {
            return GlobalFunction::sendSimpleResponse(false, 'Coupon not found');
        }
        $item->status = intval($request->status) === 1 ? 1 : 0;
        $item->save();

        return GlobalFunction::sendSimpleResponse(true, 'Status changed successfully!');
    }
}
