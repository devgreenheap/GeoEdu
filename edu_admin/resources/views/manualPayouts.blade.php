@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/manualPayouts.js') }}"></script>
@endsection
@section('content')

<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item" role="presentation"><a class="nav-link active" data-bs-toggle="tab" href="#host-payout-tab" role="tab">{{ __('Host Payout') }}</a></li>
    <li class="nav-item" role="presentation"><a class="nav-link" data-bs-toggle="tab" href="#admin-payout-tab" role="tab">{{ __('Admin Payout') }}</a></li>
    <li class="nav-item" role="presentation"><a class="nav-link" data-bs-toggle="tab" href="#agent-payout-tab" role="tab">{{ __('Agent Payout') }}</a></li>
    <li class="nav-item" role="presentation"><a class="nav-link" data-bs-toggle="tab" href="#state-agent-payout-tab" role="tab">{{ __('State Agent Payout') }}</a></li>
    <li class="nav-item" role="presentation"><a class="nav-link" data-bs-toggle="tab" href="#gifter-wallet-tab" role="tab">{{ __('Gifter Wallet') }}</a></li>
</ul>

<div class="tab-content">
    <div class="tab-pane fade show active" id="host-payout-tab" role="tabpanel">
        <div class="card mb-3">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Today Host Payout List') }} - {{ now()->format('Y-m-d') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="todayPayoutUsersTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('User') }}</th><th>{{ __('Available Stars') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Date') }}</th><th class="text-end">{{ __('Action') }}</th></tr></thead></table></div></div>
        </div>
        <div class="card">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Host Payout History') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="manualPayoutsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('ID') }}</th><th>{{ __('User') }}</th><th>{{ __('Stars Deducted') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Transaction Id') }}</th><th>{{ __('Description') }}</th><th>{{ __('Paid Date') }}</th></tr></thead></table></div></div>
        </div>
    </div>

    <div class="tab-pane fade" id="admin-payout-tab" role="tabpanel">
        <div class="card mb-3">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Today Admin Payout') }} - {{ now()->format('Y-m-d') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="todayAdminPayoutTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('Wallet') }}</th><th>{{ __('Available') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Date') }}</th><th class="text-end">{{ __('Action') }}</th></tr></thead></table></div></div>
        </div>
        <div class="card">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Admin Payout History') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="manualAdminPayoutsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('ID') }}</th><th>{{ __('Wallet') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Transaction Id') }}</th><th>{{ __('Description') }}</th><th>{{ __('Paid Date') }}</th></tr></thead></table></div></div>
        </div>
    </div>

    <div class="tab-pane fade" id="agent-payout-tab" role="tabpanel">
        <div class="card mb-3">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Today Agent Payout List') }} - {{ now()->format('Y-m-d') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="todayAgentCommissionTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('Agent') }}</th><th>{{ __('Commission Wallet') }}</th><th>{{ __('Commission Total') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Date') }}</th><th class="text-end">{{ __('Action') }}</th></tr></thead></table></div></div>
        </div>
        <div class="card">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Agent Payout History') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="manualAgentPayoutsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('ID') }}</th><th>{{ __('Agent') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Transaction Id') }}</th><th>{{ __('Description') }}</th><th>{{ __('Paid Date') }}</th></tr></thead></table></div></div>
        </div>
    </div>

    <div class="tab-pane fade" id="state-agent-payout-tab" role="tabpanel">
        <div class="card mb-3">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Today State Agent Payout List') }} - {{ now()->format('Y-m-d') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="todayStateAgentPayoutTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('State Agent') }}</th><th>{{ __('Available Stars') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Date') }}</th><th class="text-end">{{ __('Action') }}</th></tr></thead></table></div></div>
        </div>
        <div class="card">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('State Agent Payout History') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="manualStateAgentPayoutsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('ID') }}</th><th>{{ __('State Agent') }}</th><th>{{ __('Stars Deducted') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Transaction Id') }}</th><th>{{ __('Description') }}</th><th>{{ __('Paid Date') }}</th></tr></thead></table></div></div>
        </div>
    </div>

    <div class="tab-pane fade" id="gifter-wallet-tab" role="tabpanel">
        <div class="card mb-3">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Today Gifter Wallet List') }} - {{ now()->format('Y-m-d') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="todayGifterWalletPayoutTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('User') }}</th><th>{{ __('Category') }}</th><th>{{ __('Wallet Stars') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Date') }}</th><th class="text-end">{{ __('Action') }}</th></tr></thead></table></div></div>
        </div>
        <div class="card">
            <div class="card-header border-bottom"><h4 class="card-title mb-0 header-title">{{ __('Gifter Wallet Payout History') }}</h4></div>
            <div class="card-body"><div class="table-responsive mt-2"><table id="manualGifterWalletPayoutsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3"><thead class="table-light"><tr><th>{{ __('ID') }}</th><th>{{ __('User') }}</th><th>{{ __('Stars Deducted') }}</th><th>{{ __('Amount') }}</th><th>{{ __('Transaction Id') }}</th><th>{{ __('Description') }}</th><th>{{ __('Paid Date') }}</th></tr></thead></table></div></div>
        </div>
    </div>
</div>

{{-- Existing Host Modal --}}
<div id="manualPayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h4 class="modal-title">{{ __('Mark Host Payout') }}</h4><button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button></div>
        <form id="manualPayoutForm" method="POST"><input type="hidden" id="user_id" name="user_id"><div class="modal-body">
            <div class="mb-2"><label class="form-label">{{ __('Available Stars') }}</label><input type="text" id="available_stars_display" class="form-control" readonly></div>
            <div class="mb-2"><label class="form-label">{{ __('Max Amount') }}</label><input type="text" id="max_payout_amount_display" class="form-control" readonly><input type="hidden" id="max_payout_amount" name="max_payout_amount"></div>
            <div class="mb-2"><label for="transferred_amount" class="form-label">{{ __('Transferred Amount') }}</label><input type="number" min="0.01" step="0.01" class="form-control" id="transferred_amount" name="transferred_amount" required></div>
            <div class="mb-2"><label class="form-label">{{ __('Payout') }}</label><input type="text" id="payout_amount_display" class="form-control" readonly></div>
            <div class="mb-2"><label for="paid_date" class="form-label">{{ __('Paid Date') }}</label><input type="datetime-local" class="form-control" id="paid_date" name="paid_date" required></div>
            <div class="mb-2"><label for="description" class="form-label">{{ __('Description') }}</label><textarea class="form-control" id="description" name="description" rows="2"></textarea></div>
            <div class="mb-2"><label for="transaction_id" class="form-label">{{ __('Transaction Id') }}</label><input type="text" class="form-control" id="transaction_id" name="transaction_id" required></div>
        </div><div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button><button type="submit" class="btn btn-primary"><span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>{{ __('Submit') }}</button></div></form>
    </div></div>
</div>

{{-- Existing Agent Modal --}}
<div id="manualAgentPayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h4 class="modal-title">{{ __('Mark Agent Payout') }}</h4><button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button></div>
        <form id="manualAgentPayoutForm" method="POST"><input type="hidden" id="agent_id" name="agent_id"><div class="modal-body">
            <div class="mb-2"><label class="form-label">{{ __('Commission Wallet') }}</label><input type="text" id="agent_wallet_display" class="form-control" readonly></div>
            <div class="mb-2"><label class="form-label">{{ __('Max Amount') }}</label><input type="text" id="agent_max_payout_amount_display" class="form-control" readonly><input type="hidden" id="agent_max_payout_amount" name="max_payout_amount"></div>
            <div class="mb-2"><label for="agent_transferred_amount" class="form-label">{{ __('Transferred Amount') }}</label><input type="number" min="0.01" step="0.01" class="form-control" id="agent_transferred_amount" name="transferred_amount" required></div>
            <div class="mb-2"><label for="agent_paid_date" class="form-label">{{ __('Paid Date') }}</label><input type="datetime-local" class="form-control" id="agent_paid_date" name="paid_date" required></div>
            <div class="mb-2"><label for="agent_description" class="form-label">{{ __('Description') }}</label><textarea class="form-control" id="agent_description" name="description" rows="2"></textarea></div>
            <div class="mb-2"><label for="agent_transaction_id" class="form-label">{{ __('Transaction Id') }}</label><input type="text" class="form-control" id="agent_transaction_id" name="transaction_id" required></div>
        </div><div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button><button type="submit" class="btn btn-primary"><span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>{{ __('Submit') }}</button></div></form>
    </div></div>
</div>

{{-- Admin Modal --}}
<div id="manualAdminPayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h4 class="modal-title">{{ __('Mark Admin Payout') }}</h4><button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button></div>
        <form id="manualAdminPayoutForm" method="POST"><div class="modal-body">
            <div class="mb-2"><label class="form-label">{{ __('Admin Wallet') }}</label><input type="text" id="admin_wallet_display" class="form-control" readonly></div>
            <div class="mb-2"><label class="form-label">{{ __('Max Amount') }}</label><input type="text" id="admin_max_payout_amount_display" class="form-control" readonly><input type="hidden" id="admin_max_payout_amount"></div>
            <div class="mb-2"><label class="form-label">{{ __('Transferred Amount') }}</label><input type="number" min="0.01" step="0.01" class="form-control" id="admin_transferred_amount" name="transferred_amount" required></div>
            <div class="mb-2"><label class="form-label">{{ __('Paid Date') }}</label><input type="datetime-local" class="form-control" id="admin_paid_date" name="paid_date" required></div>
            <div class="mb-2"><label class="form-label">{{ __('Description') }}</label><textarea class="form-control" id="admin_description" name="description" rows="2"></textarea></div>
            <div class="mb-2"><label class="form-label">{{ __('Transaction Id') }}</label><input type="text" class="form-control" id="admin_transaction_id" name="transaction_id" required></div>
        </div><div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button><button type="submit" class="btn btn-primary"><span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>{{ __('Submit') }}</button></div></form>
    </div></div>
</div>

{{-- State Agent Modal --}}
<div id="manualStateAgentPayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h4 class="modal-title">{{ __('Mark State Agent Payout') }}</h4><button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button></div>
        <form id="manualStateAgentPayoutForm" method="POST"><input type="hidden" id="state_agent_user_id" name="user_id"><div class="modal-body">
            <div class="mb-2"><label class="form-label">{{ __('Available Stars') }}</label><input type="text" id="state_agent_stars_display" class="form-control" readonly></div>
            <div class="mb-2"><label class="form-label">{{ __('Max Amount') }}</label><input type="text" id="state_agent_max_payout_amount_display" class="form-control" readonly><input type="hidden" id="state_agent_max_payout_amount"></div>
            <div class="mb-2"><label class="form-label">{{ __('Transferred Amount') }}</label><input type="number" min="0.01" step="0.01" class="form-control" id="state_agent_transferred_amount" name="transferred_amount" required></div>
            <div class="mb-2"><label class="form-label">{{ __('Paid Date') }}</label><input type="datetime-local" class="form-control" id="state_agent_paid_date" name="paid_date" required></div>
            <div class="mb-2"><label class="form-label">{{ __('Description') }}</label><textarea class="form-control" id="state_agent_description" name="description" rows="2"></textarea></div>
            <div class="mb-2"><label class="form-label">{{ __('Transaction Id') }}</label><input type="text" class="form-control" id="state_agent_transaction_id" name="transaction_id" required></div>
        </div><div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button><button type="submit" class="btn btn-primary"><span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>{{ __('Submit') }}</button></div></form>
    </div></div>
</div>

{{-- Gifter Wallet Modal --}}
<div id="manualGifterWalletPayoutModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog"><div class="modal-content"><div class="modal-header"><h4 class="modal-title">{{ __('Mark Gifter Wallet Payout') }}</h4><button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button></div>
        <form id="manualGifterWalletPayoutForm" method="POST"><input type="hidden" id="gifter_wallet_user_id" name="user_id"><input type="hidden" id="gifter_wallet_category_id" name="gift_category_id"><div class="modal-body">
            <div class="mb-2"><label class="form-label">{{ __('Category') }}</label><input type="text" id="gifter_wallet_category_display" class="form-control" readonly></div>
            <div class="mb-2"><label class="form-label">{{ __('Wallet Stars') }}</label><input type="text" id="gifter_wallet_stars_display" class="form-control" readonly></div>
            <div class="mb-2"><label class="form-label">{{ __('Max Amount') }}</label><input type="text" id="gifter_wallet_max_payout_amount_display" class="form-control" readonly><input type="hidden" id="gifter_wallet_max_payout_amount"></div>
            <div class="mb-2"><label class="form-label">{{ __('Transferred Amount') }}</label><input type="number" min="0.01" step="0.01" class="form-control" id="gifter_wallet_transferred_amount" name="transferred_amount" required></div>
            <div class="mb-2"><label class="form-label">{{ __('Paid Date') }}</label><input type="datetime-local" class="form-control" id="gifter_wallet_paid_date" name="paid_date" required></div>
            <div class="mb-2"><label class="form-label">{{ __('Description') }}</label><textarea class="form-control" id="gifter_wallet_description" name="description" rows="2"></textarea></div>
            <div class="mb-2"><label class="form-label">{{ __('Transaction Id') }}</label><input type="text" class="form-control" id="gifter_wallet_transaction_id" name="transaction_id" required></div>
        </div><div class="modal-footer"><button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button><button type="submit" class="btn btn-primary"><span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>{{ __('Submit') }}</button></div></form>
    </div></div>
</div>

@endsection
