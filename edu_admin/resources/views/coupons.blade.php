@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/coupons.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('Coupons') }}</h4>
        <a data-bs-toggle="modal" data-bs-target="#addCouponModal" class="btn btn-dark ms-auto">{{ __('Add Coupon') }}</a>
    </div>
    <div class="card-body">
        <div class="table-responsive mt-2">
            <table id="couponsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Coupon Code') }}</th>
                        <th>{{ __('Discount Type') }}</th>
                        <th>{{ __('Discount Value') }}</th>
                        <th>{{ __('End Date') }}</th>
                        <th>{{ __('No. of Users') }}</th>
                        <th>{{ __('Used Users') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="addCouponModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add Coupon') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addCouponForm" method="POST">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="coupon_code" class="form-label">{{ __('Coupon Code') }}</label>
                        <input class="form-control text-uppercase" type="text" id="coupon_code" name="coupon_code" required>
                    </div>
                    <div class="mb-2">
                        <label for="discount_type" class="form-label">{{ __('Discount Type') }}</label>
                        <select class="form-control" id="discount_type" name="discount_type" required>
                            <option value="percentage">{{ __('Percentage') }}</option>
                            <option value="amount">{{ __('Amount') }}</option>
                        </select>
                    </div>
                    <div class="mb-2">
                        <label for="discount_value" class="form-label">{{ __('Discount Value') }}</label>
                        <input class="form-control" type="number" min="0" step="0.01" id="discount_value" name="discount_value" required>
                    </div>
                    <div class="mb-2 form-check">
                        <input type="checkbox" class="form-check-input" id="add_unlimited_end_date" name="unlimited_end_date" value="1">
                        <label class="form-check-label" for="add_unlimited_end_date">{{ __('Unlimited End Date') }}</label>
                    </div>
                    <div class="mb-2">
                        <label for="end_date" class="form-label">{{ __('End Date') }}</label>
                        <input class="form-control" type="date" id="end_date" name="end_date">
                    </div>
                    <div class="mb-2 form-check">
                        <input type="checkbox" class="form-check-input" id="add_unlimited_users" name="unlimited_users" value="1">
                        <label class="form-check-label" for="add_unlimited_users">{{ __('Unlimited Users') }}</label>
                    </div>
                    <div class="mb-2">
                        <label for="max_users" class="form-label">{{ __('No. of Users') }}</label>
                        <input class="form-control" type="number" min="1" id="max_users" name="max_users">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="editCouponModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit Coupon') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editCouponForm" method="POST">
                <input type="hidden" name="id" id="editCouponId">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="edit_coupon_code" class="form-label">{{ __('Coupon Code') }}</label>
                        <input class="form-control text-uppercase" type="text" id="edit_coupon_code" name="coupon_code" required>
                    </div>
                    <div class="mb-2">
                        <label for="edit_discount_type" class="form-label">{{ __('Discount Type') }}</label>
                        <select class="form-control" id="edit_discount_type" name="discount_type" required>
                            <option value="percentage">{{ __('Percentage') }}</option>
                            <option value="amount">{{ __('Amount') }}</option>
                        </select>
                    </div>
                    <div class="mb-2">
                        <label for="edit_discount_value" class="form-label">{{ __('Discount Value') }}</label>
                        <input class="form-control" type="number" min="0" step="0.01" id="edit_discount_value" name="discount_value" required>
                    </div>
                    <div class="mb-2 form-check">
                        <input type="checkbox" class="form-check-input" id="edit_unlimited_end_date" name="unlimited_end_date" value="1">
                        <label class="form-check-label" for="edit_unlimited_end_date">{{ __('Unlimited End Date') }}</label>
                    </div>
                    <div class="mb-2">
                        <label for="edit_end_date" class="form-label">{{ __('End Date') }}</label>
                        <input class="form-control" type="date" id="edit_end_date" name="end_date">
                    </div>
                    <div class="mb-2 form-check">
                        <input type="checkbox" class="form-check-input" id="edit_unlimited_users" name="unlimited_users" value="1">
                        <label class="form-check-label" for="edit_unlimited_users">{{ __('Unlimited Users') }}</label>
                    </div>
                    <div class="mb-2">
                        <label for="edit_max_users" class="form-label">{{ __('No. of Users') }}</label>
                        <input class="form-control" type="number" min="1" id="edit_max_users" name="max_users">
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Submit') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
