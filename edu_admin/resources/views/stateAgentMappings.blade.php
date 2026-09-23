@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/stateAgentMappings.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('State Agent') }}</h4>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table id="stateAgentMappingsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Country') }}</th>
                        <th>{{ __('State') }}</th>
                        <th>{{ __('Agent') }}</th>
                        <th style="width: 120px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
