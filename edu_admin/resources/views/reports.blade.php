@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/reports.js') }}"></script>
@endsection
@section('content')
@php($activeReportTab = $activeReportTab ?? 'revenue')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('Reports') }}</h4>
    </div>
    <div class="card-body">
        <div class="row g-2 mb-3">
            <div class="col-md-3">
                <label class="form-label mb-1">{{ __('Start Date') }}</label>
                <input type="date" id="reportStartDate" class="form-control">
            </div>
            <div class="col-md-3">
                <label class="form-label mb-1">{{ __('End Date') }}</label>
                <input type="date" id="reportEndDate" class="form-control">
            </div>
            <div class="col-md-3 d-flex align-items-end">
                <button type="button" id="applyReportFilters" class="btn btn-primary me-2">{{ __('Apply') }}</button>
                <button type="button" id="resetReportFilters" class="btn btn-light">{{ __('Reset') }}</button>
            </div>
        </div>
        @if($activeReportTab === 'revenue')
            <h5 class="mb-2">{{ __('Revenue & Commission') }}</h5>
            <div class="table-responsive"><table id="revenueCommissionTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('Metric') }}</th><th>{{ __('Value') }}</th><th>{{ __('Notes') }}</th></tr></thead></table></div>
        @elseif($activeReportTab === 'payout')
            <h5 class="mb-2">{{ __('Payout Control') }}</h5>
            <div class="table-responsive"><table id="payoutControlTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('Payout Type') }}</th><th>{{ __('Pending Amount') }}</th><th>{{ __('Paid In Range') }}</th><th>{{ __('Last Paid At') }}</th></tr></thead></table></div>
        @elseif($activeReportTab === 'live')
            <h5 class="mb-2">{{ __('Live Performance') }}</h5>
            <div class="table-responsive"><table id="livePerformanceTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('Host') }}</th><th>{{ __('Total Lives') }}</th><th>{{ __('Ended Lives') }}</th><th>{{ __('Total Duration (Min)') }}</th><th>{{ __('Avg Duration (Min)') }}</th></tr></thead></table></div>
        @elseif($activeReportTab === 'growth')
            <h5 class="mb-2">{{ __('User Growth & Quality') }}</h5>
            <div class="table-responsive"><table id="userGrowthQualityTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('Date') }}</th><th>{{ __('New Users') }}</th><th>{{ __('Real') }}</th><th>{{ __('Dummy') }}</th><th>{{ __('Verified') }}</th><th>{{ __('Verified %') }}</th><th>{{ __('Active Users') }}</th></tr></thead></table></div>
        @elseif($activeReportTab === 'gift')
            <h5 class="mb-2">{{ __('Gift Analytics') }}</h5>
            <div class="table-responsive"><table id="giftAnalyticsTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('Category') }}</th><th>{{ __('Source') }}</th><th>{{ __('Gifts') }}</th><th>{{ __('Total Diamonds') }}</th><th>{{ __('Unique Senders') }}</th><th>{{ __('Unique Receivers') }}</th></tr></thead></table></div>
        @elseif($activeReportTab === 'agent')
            <h5 class="mb-2">{{ __('Agent & State Agent') }}</h5>
            <div class="table-responsive"><table id="agentStatePerformanceTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('Agent') }}</th><th>{{ __('State Agent') }}</th><th>{{ __('Total Referrals') }}</th><th>{{ __('Active Referrals') }}</th><th>{{ __('Commission Entries') }}</th><th>{{ __('Commission Amount') }}</th></tr></thead></table></div>
        @elseif($activeReportTab === 'moderation')
            <h5 class="mb-2">{{ __('Moderation & Risk') }}</h5>
            <div class="table-responsive"><table id="moderationRiskTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('User') }}</th><th>{{ __('User Reports') }}</th><th>{{ __('Post Reports') }}</th><th>{{ __('Total Reports') }}</th><th>{{ __('Status') }}</th></tr></thead></table></div>
        @else
            <h5 class="mb-2">{{ __('Revenue & Commission') }}</h5>
                <div class="table-responsive"><table id="revenueCommissionTable" class="table table-centered table-hover w-100 mt-2"><thead class="table-light"><tr><th>{{ __('Metric') }}</th><th>{{ __('Value') }}</th><th>{{ __('Notes') }}</th></tr></thead></table></div>
        @endif
    </div>
</div>
@endsection
