@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/screenshotDisableRequests.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title me-3">{{ __('Screenshot Disable Requests') }}</h4>
        <div class="nav nav-pills flex-nowrap" id="screenshot-disable-tab" role="tablist" aria-orientation="horizontal" style="gap: 8px;">
            <a class="nav-link active show screenshot-disable-tab-link" data-status="0" href="#" role="tab" style="white-space: nowrap;">
                <span>{{ __('Pending') }}</span>
            </a>
            <a class="nav-link screenshot-disable-tab-link" data-status="1" href="#" role="tab" style="white-space: nowrap;">
                <span>{{ __('Approved') }}</span>
            </a>
        </div>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table class="table table-centered table-hover w-100 dt-responsive nowrap mt-3" id="screenshotDisableRequestsTable">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Request ID') }}</th>
                        <th>{{ __('User') }}</th>
                        <th>{{ __('Reason') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th>{{ __('Approved By') }}</th>
                        <th style="width: 140px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
