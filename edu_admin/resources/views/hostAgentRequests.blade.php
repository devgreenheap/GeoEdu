@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/hostAgentRequests.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title me-3">
            {{ __('Host / Agent Requests') }}
        </h4>
        <div class="nav nav-pills flex-nowrap" id="v-pills-tab" role="tablist" aria-orientation="horizontal" style="gap: 8px;">
            <a class="nav-link active show" id="v-pills-pending-tab" data-bs-toggle="pill" href="#v-pills-pending" role="tab" aria-controls="v-pills-pending" aria-selected="true" style="white-space: nowrap;">
                <span>{{ __('Pending') }}</span>
            </a>
            <a class="nav-link" id="v-pills-accepted-tab" data-bs-toggle="pill" href="#v-pills-accepted" role="tab" aria-controls="v-pills-accepted" aria-selected="false" style="white-space: nowrap;">
                <span>{{ __('Accepted') }}</span>
            </a>
            <a class="nav-link" id="v-pills-rejected-tab" data-bs-toggle="pill" href="#v-pills-rejected" role="tab" aria-controls="v-pills-rejected" aria-selected="false" style="white-space: nowrap;">
                <span>{{ __('Rejected') }}</span>
            </a>
        </div>
    </div>
    <div class="card-body">
        <div class="tab-content mt-1" id="v-pills-tabContent">
            <div class="tab-pane fade active show" id="v-pills-pending" role="tabpanel" aria-labelledby="v-pills-pending-tab">
                <div class="table-responsive">
                    <table class="table table-centered table-hover w-100 dt-responsive nowrap mt-3" id="pendingHostAgentRequestsTable">
                        <thead class="table-light">
                            <tr>
                                <th>{{ __('Request ID')}}</th>
                                <th>{{ __('Type')}}</th>
                                <th>{{ __('User')}}</th>
                                <th>{{ __('Verification Photo')}}</th>
                                <th>{{ __('Interview Video')}}</th>
                                <th>{{ __('Requested Date')}}</th>
                                <th>{{ __('Status')}}</th>
                                <th style="width: 200px;" class="text-end">{{ __('Action')}}</th>
                            </tr>
                        </thead>
                    </table>
                </div>
            </div>
            <div class="tab-pane fade" id="v-pills-accepted" role="tabpanel" aria-labelledby="v-pills-accepted-tab">
                <div class="table-responsive">
                    <table class="table table-centered table-hover w-100 dt-responsive nowrap mt-3" id="acceptedHostAgentRequestsTable">
                        <thead class="table-light">
                            <tr>
                                <th>{{ __('Request ID')}}</th>
                                <th>{{ __('Type')}}</th>
                                <th>{{ __('User')}}</th>
                                <th>{{ __('Verification Photo')}}</th>
                                <th>{{ __('Interview Video')}}</th>
                                <th>{{ __('Requested Date')}}</th>
                                <th>{{ __('Action Date')}}</th>
                                <th>{{ __('Status')}}</th>
                            </tr>
                        </thead>
                    </table>
                </div>
            </div>
            <div class="tab-pane fade" id="v-pills-rejected" role="tabpanel" aria-labelledby="v-pills-rejected-tab">
                <div class="table-responsive">
                    <table class="table table-centered table-hover w-100 dt-responsive nowrap mt-3" id="rejectedHostAgentRequestsTable">
                        <thead class="table-light">
                            <tr>
                                <th>{{ __('Request ID')}}</th>
                                <th>{{ __('Type')}}</th>
                                <th>{{ __('User')}}</th>
                                <th>{{ __('Verification Photo')}}</th>
                                <th>{{ __('Interview Video')}}</th>
                                <th>{{ __('Requested Date')}}</th>
                                <th>{{ __('Action Date')}}</th>
                                <th>{{ __('Status')}}</th>
                            </tr>
                        </thead>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>

{{-- Interview Video Player Modal --}}
<div class="modal fade" id="videoPlayerModal" tabindex="-1" aria-labelledby="videoPlayerModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered modal-lg">
        <div class="modal-content bg-dark text-white rounded-3 shadow">
            <div class="modal-header border-secondary">
                <h5 class="modal-title" id="videoPlayerModalLabel"><i class="uil-video me-1 text-primary"></i> {{ __('Interview Video') }}</h5>
                <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal" aria-label="Close"></button>
            </div>
            <div class="modal-body p-0 text-center bg-black">
                <video id="modalInterviewVideo" controls class="w-100" style="max-height: 70vh; outline: none; background: #000;" playsinline>
                    <source src="" type="video/mp4">
                    {{ __('Your browser does not support the video tag.') }}
                </video>
            </div>
            <div class="modal-footer border-secondary justify-content-between">
                <span id="modalVideoUserInfo" class="text-white-50 small"></span>
                <button type="button" class="btn btn-secondary btn-sm" data-bs-dismiss="modal">{{ __('Close') }}</button>
            </div>
        </div>
    </div>
</div>

@endsection
