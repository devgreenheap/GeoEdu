@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/requestedPayouts.js') }}"></script>
@endsection
@section('content')

<div class="row">
    <div class="col-12">
        <div class="page-title-box">
            <div class="page-title-right">
                <ol class="breadcrumb m-0">
                    <li class="breadcrumb-item"><a href="{{ url('dashboard') }}">{{ __('Dashboard') }}</a></li>
                    <li class="breadcrumb-item"><a href="{{ url('manualPayouts') }}">{{ __('Transactions') }}</a></li>
                    <li class="breadcrumb-item active">{{ __('Requested Payouts') }}</li>
                </ol>
            </div>
            <h4 class="page-title">{{ __('Host Requested Payouts') }}</h4>
        </div>
    </div>
</div>

<!-- Summary Stats Cards -->
<div class="row">
    <div class="col-md-6 col-xl-3">
        <div class="card card-widget">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="text-muted text-uppercase mt-0 mb-1">{{ __('Total Requests') }}</h6>
                        <h2 class="my-2" id="stat_total">{{ $totalRequests }}</h2>
                    </div>
                    <div class="avatar-sm rounded-circle bg-primary-lighten d-flex align-items-center justify-content-center">
                        <i class="uil-file-alt text-primary font-24"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-6 col-xl-3">
        <div class="card card-widget">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="text-muted text-uppercase mt-0 mb-1">{{ __('Pending Approval') }}</h6>
                        <h2 class="my-2 text-warning" id="stat_pending">{{ $pendingRequests }}</h2>
                    </div>
                    <div class="avatar-sm rounded-circle bg-warning-lighten d-flex align-items-center justify-content-center">
                        <i class="uil-clock text-warning font-24"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-6 col-xl-3">
        <div class="card card-widget">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="text-muted text-uppercase mt-0 mb-1">{{ __('Paid / Approved') }}</h6>
                        <h2 class="my-2 text-success" id="stat_approved">{{ $approvedRequests }}</h2>
                    </div>
                    <div class="avatar-sm rounded-circle bg-success-lighten d-flex align-items-center justify-content-center">
                        <i class="uil-check-circle text-success font-24"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-md-6 col-xl-3">
        <div class="card card-widget">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center">
                    <div>
                        <h6 class="text-muted text-uppercase mt-0 mb-1">{{ __('Rejected') }}</h6>
                        <h2 class="my-2 text-danger" id="stat_rejected">{{ $rejectedRequests }}</h2>
                    </div>
                    <div class="avatar-sm rounded-circle bg-danger-lighten d-flex align-items-center justify-content-center">
                        <i class="uil-times-circle text-danger font-24"></i>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Main Table Card -->
<div class="card">
    <div class="card-header d-flex flex-wrap align-items-center justify-content-between border-bottom pb-2">
        <h4 class="card-title mb-0 header-title">{{ __('All Host Conversion Requests') }}</h4>
        <div class="d-flex align-items-center gap-2 mt-2 mt-md-0">
            <label class="form-label mb-0 me-1 text-muted">{{ __('Filter Status:') }}</label>
            <select id="statusFilter" class="form-select form-select-sm" style="width: 170px;">
                <option value="all">{{ __('All Requests') }}</option>
                <option value="0" selected>{{ __('Pending Approval') }}</option>
                <option value="1">{{ __('Paid / Approved') }}</option>
                <option value="2">{{ __('Rejected') }}</option>
            </select>
            <button id="refreshBtn" class="btn btn-sm btn-outline-secondary" title="Refresh Table">
                <i class="uil-sync"></i>
            </button>
        </div>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table id="requestedPayoutsTable" class="table table-centered table-hover w-100 dt-responsive nowrap">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Request ID') }}</th>
                        <th>{{ __('Host / User') }}</th>
                        <th>{{ __('Available Stars') }}</th>
                        <th>{{ __('Category') }}</th>
                        <th>{{ __('Requested Amount') }}</th>
                        <th>{{ __('Payout Details') }}</th>
                        <th>{{ __('Request Date') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th>{{ __('Payment Confirmation') }}</th>
                        <th class="text-end">{{ __('Actions') }}</th>
                    </tr>
                </thead>
                <tbody></tbody>
            </table>
        </div>
    </div>
</div>

<!-- Payment Confirmation & Approval Modal -->
<div id="approvePayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true" data-bs-backdrop="static">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-success text-white">
                <h4 class="modal-title text-white"><i class="uil-money-withdraw me-1"></i> {{ __('Admin Payment Confirmation & Approval') }}</h4>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="approvePayoutForm" method="POST">
                <input type="hidden" id="approve_payout_id" name="id">
                <div class="modal-body">
                    <div class="alert alert-info d-flex align-items-center" role="alert">
                        <i class="uil-info-circle font-20 me-2"></i>
                        <div>
                            {{ __('Please perform the actual transfer to the host via Bank or UPI, then enter the payment confirmation details below to complete and approve this payout.') }}
                        </div>
                    </div>

                    <!-- Host & Payout Summary Card -->
                    <div class="card border mb-3">
                        <div class="card-body p-3 bg-light rounded">
                            <div class="row g-2">
                                <div class="col-md-6">
                                    <div class="text-muted small">{{ __('Host Name') }}</div>
                                    <h5 class="my-1" id="approve_host_name">-</h5>
                                    <div class="text-muted small" id="approve_host_info">-</div>
                                </div>
                                <div class="col-md-6">
                                    <div class="text-muted small">{{ __('Conversion Request') }}</div>
                                    <h4 class="text-primary my-1" id="approve_req_amount">-</h4>
                                    <div class="text-muted small" id="approve_req_stars">-</div>
                                </div>
                                <div class="col-12 mt-2 pt-2 border-top">
                                    <div class="text-muted small mb-1">{{ __('Transfer Details (Destination)') }}</div>
                                    <div id="approve_payout_target_details" class="p-2 bg-white rounded border small">
                                        <!-- Loaded dynamically -->
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>

                    <h5 class="mb-3 text-success"><i class="uil-check-circle me-1"></i> {{ __('Enter Payment Details (All Mandatory)') }}</h5>
                    <div class="row g-3">
                        <div class="col-md-6">
                            <label for="approve_transaction_id" class="form-label fw-bold">{{ __('Transaction ID') }} <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="uil-receipt"></i></span>
                                <input type="text" class="form-control" id="approve_transaction_id" name="transaction_id" placeholder="e.g. UTR123456789 or TXN987654321" required>
                            </div>
                            <small class="text-muted">{{ __('Bank Reference / UPI Reference number') }}</small>
                        </div>

                        <div class="col-md-6">
                            <label for="approve_paid_amount" class="form-label fw-bold">{{ __('Paid Amount') }} <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <span class="input-group-text">{{ $currency }}</span>
                                <input type="number" step="0.01" min="0.01" class="form-control" id="approve_paid_amount" name="paid_amount" required>
                            </div>
                            <small class="text-muted">{{ __('Exact money sent to the host account') }}</small>
                        </div>

                        <div class="col-md-6">
                            <label for="approve_payment_date" class="form-label fw-bold">{{ __('Payment Date') }} <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="uil-calendar-alt"></i></span>
                                <input type="date" class="form-control" id="approve_payment_date" name="payment_date" required>
                            </div>
                        </div>

                        <div class="col-md-6">
                            <label for="approve_payment_time" class="form-label fw-bold">{{ __('Payment Time') }} <span class="text-danger">*</span></label>
                            <div class="input-group">
                                <span class="input-group-text"><i class="uil-clock"></i></span>
                                <input type="time" class="form-control" id="approve_payment_time" name="payment_time" required>
                            </div>
                        </div>

                        <div class="col-12">
                            <label for="approve_admin_note" class="form-label">{{ __('Admin Note (Optional)') }}</label>
                            <textarea class="form-control" id="approve_admin_note" name="admin_note" rows="2" placeholder="Optional notes for internal record or host confirmation"></textarea>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                    <button type="submit" class="btn btn-success" id="confirmApproveBtn">
                        <span class="spinner-border spinner-border-sm me-1 hide" role="status" aria-hidden="true"></span>
                        <i class="uil-check-circle me-1"></i> {{ __('Confirm Payment & Approve') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<!-- View Payout Details Modal -->
<div id="viewPayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content">
            <div class="modal-header bg-light">
                <h4 class="modal-title"><i class="uil-eye me-1"></i> {{ __('Payout Request Details') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <div class="modal-body" id="viewPayoutBody">
                <div class="text-center py-4">
                    <div class="spinner-border text-primary" role="status"></div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">{{ __('Close') }}</button>
            </div>
        </div>
    </div>
</div>

<!-- Reject Modal -->
<div id="rejectPayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header bg-danger text-white">
                <h4 class="modal-title text-white"><i class="uil-times-circle me-1"></i> {{ __('Reject Payout Request') }}</h4>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="rejectPayoutForm" method="POST">
                <input type="hidden" id="reject_payout_id" name="id">
                <div class="modal-body">
                    <p class="text-muted">{{ __('Are you sure you want to reject this payout request? The deducted stars will be automatically refunded back to the host\'s wallet.') }}</p>
                    <div class="mb-3">
                        <label for="reject_admin_note" class="form-label">{{ __('Reason for Rejection') }}</label>
                        <textarea class="form-control" id="reject_admin_note" name="admin_note" rows="3" placeholder="Provide a reason (e.g. Invalid bank account details, UPI ID not active, etc.)" required></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Cancel') }}</button>
                    <button type="submit" class="btn btn-danger" id="confirmRejectBtn">
                        <span class="spinner-border spinner-border-sm me-1 hide" role="status" aria-hidden="true"></span>
                        <i class="uil-times me-1"></i> {{ __('Reject & Refund Stars') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
