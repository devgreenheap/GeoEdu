@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/agentSettings.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="m-0 header-title">{{ __('Agent') }}</h4>
    </div>
    <div class="card-body">
        <form id="agentSettingsForm" method="POST">
            <div class="mb-3">
                <label for="agent_commission" class="form-label">{{ __('Commission') }}</label>
                <input class="form-control" type="number" min="0" step="0.01" id="agent_commission" name="agent_commission"
                    value="{{ $setting->agent_commission ?? 0 }}" required>
            </div>
            <div class="mb-3">
                <label for="agent_commission_min_withdraw" class="form-label">{{ __('Minimum Withdraw Limit') }}</label>
                <input class="form-control" type="number" min="0" step="0.01" id="agent_commission_min_withdraw" name="agent_commission_min_withdraw"
                    value="{{ $setting->agent_commission_min_withdraw ?? 0 }}" required>
            </div>
            <div>
                <button type="submit" class="btn btn-primary">
                    <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                    {{ __('Save') }}
                </button>
            </div>
        </form>
    </div>
</div>

@endsection
