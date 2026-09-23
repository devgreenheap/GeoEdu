@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/users.js') }}"></script>
@endsection
@section('content')

<div class="mb-2">
</div>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            <div class="nav nav-pills" id="v-pills-tab" role="tablist" aria-orientation="vertical">
                <a class="nav-link active show" id="v-pills-users-tab" data-bs-toggle="pill" href="#v-pills-users" role="tab" aria-controls="v-pills-users"
                aria-selected="false">
                <span class="d-md-block">{{__('All')}}</span>
                 </a>
                <a class="nav-link" id="v-pills-host-agent-requests-tab" data-bs-toggle="pill" href="#v-pills-host-agent-requests" role="tab" aria-controls="v-pills-host-agent-requests"
                    aria-selected="false">
                    <span class="d-md-block">{{__('Host/Agent Request')}}</span>
                </a>
                <a class="nav-link" id="v-pills-state-agent-tab" data-bs-toggle="pill" href="#v-pills-state-agent" role="tab" aria-controls="v-pills-state-agent"
                    aria-selected="false">
                    <span class="d-md-block">{{__('State Agent')}}</span>
                </a>
                <a class="nav-link" id="v-pills-screenshot-disable-tab" data-bs-toggle="pill" href="#v-pills-screenshot-disable" role="tab" aria-controls="v-pills-screenshot-disable"
                    aria-selected="false">
                    <span class="d-md-block">{{__('Screenshot Disable Request')}}</span>
                </a>
            </div>
        </h4>
    </div>
    <div class="card-body">
        <div class="tab-content mt-3" id="v-pills-tabContent">
             {{-- All Users --}}
             <div class="tab-pane fade active show" id="v-pills-users" role="tabpanel" aria-labelledby="v-pills-users-tab">
                <div class="row g-2 mb-3">
                    <div class="col-md-2">
                        <label class="form-label mb-1">{{ __('Level') }}</label>
                        <select id="filterLevelId" class="form-control">
                            <option value="">{{ __('All') }}</option>
                            @foreach ($levels as $level)
                                <option value="{{ $level->id }}">{{ __('Level') }} {{ $level->level }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label mb-1">{{ __('Real/Dummy') }}</label>
                        <select id="filterUserType" class="form-control">
                            <option value="all">{{ __('All') }}</option>
                            <option value="real">{{ __('Real') }}</option>
                            <option value="dummy">{{ __('Dummy') }}</option>
                        </select>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label mb-1">{{ __('User Type') }}</label>
                        <select id="filterRoleType" class="form-control">
                            <option value="all">{{ __('All') }}</option>
                            <option value="user">{{ __('User') }}</option>
                            <option value="host">{{ __('Host') }}</option>
                            <option value="agent">{{ __('Agent') }}</option>
                            <option value="state_agent">{{ __('State Agent') }}</option>
                        </select>
                    </div>
                    <div class="col-md-2 position-relative">
                        <label class="form-label mb-1">{{ __('Name') }}</label>
                        <input type="text" id="filterUserName" class="form-control" placeholder="{{ __('Search name') }}" autocomplete="off">
                        <input type="hidden" id="filterUserId">
                        <div id="nameAutocompleteList" class="list-group position-absolute w-100 d-none" style="z-index: 1050; max-height: 220px; overflow-y: auto;"></div>
                    </div>
                    <div class="col-md-2">
                        <label class="form-label mb-1">{{ __('Mobile') }}</label>
                        <input type="text" id="filterMobile" class="form-control" placeholder="{{ __('Search mobile') }}">
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <button type="button" id="applyUsersFilter" class="btn btn-primary me-2">{{ __('Apply') }}</button>
                        <button type="button" id="resetUsersFilter" class="btn btn-light">{{ __('Reset') }}</button>
                    </div>
                </div>
                <div class="table-responsive">
                    <table id="usersTable" class="table table-centered table-hover w-100 dt-responsive mt-3">
                        <thead class="table-light">
                            <tr>
                                <th>{{ __('S.No')}}</th>
                                <th>{{ __('User')}}</th>
                                <th>{{ __('Real/Dummy')}}</th>
                                <th>{{ __('Identity')}}</th>
                                <th>{{ __('Mobile')}}</th>
                                <th>{{ __('Learning Details')}}</th>
                                <th>{{ __('Freeze')}}</th>
                                <th>{{ __('Moderator')}}</th>
                                <th style="width: 140px;" class="text-end">{{ __('Action')}}</th>
                            </tr>
                        </thead>
                    </table>
                </div>
            </div>
            {{-- Host / Agent Requests --}}
            <div class="tab-pane fade" id="v-pills-host-agent-requests" role="tabpanel" aria-labelledby="v-pills-host-agent-requests-tab">
                <iframe id="hostAgentRequestsFrame" class="w-100 border rounded-2" style="min-height: 640px;" data-loaded="0"></iframe>
            </div>
            {{-- State Agent --}}
            <div class="tab-pane fade" id="v-pills-state-agent" role="tabpanel" aria-labelledby="v-pills-state-agent-tab">
                <iframe id="stateAgentMappingsFrame" class="w-100 border rounded-2" style="min-height: 640px;" data-loaded="0"></iframe>
            </div>
            {{-- Screenshot Disable Requests --}}
            <div class="tab-pane fade" id="v-pills-screenshot-disable" role="tabpanel" aria-labelledby="v-pills-screenshot-disable-tab">
                <iframe id="screenshotDisableRequestsFrame" class="w-100 border rounded-2" style="min-height: 640px;" data-loaded="0"></iframe>
            </div>
        </div> <!-- end tab-content-->
    </div>
</div>

@endsection
