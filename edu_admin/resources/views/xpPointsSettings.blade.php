@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/xpPointsSettings.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="m-0 header-title">{{ __('XP Points Set') }}</h4>
    </div>
    <div class="card-body">
        <form id="xpPointsSettingsForm" method="POST">
            <div class="mb-3">
                <label for="xp_comments_on_live" class="form-label">{{ __('Comments on live') }}</label>
                <input class="form-control" type="number" min="0" id="xp_comments_on_live" name="xp_comments_on_live"
                    value="{{ intval($setting->xp_comments_on_live ?? 0) }}" required>
            </div>
            <div class="mb-3">
                <label for="xp_follow_host" class="form-label">{{ __('Follow a host') }}</label>
                <input class="form-control" type="number" min="0" id="xp_follow_host" name="xp_follow_host"
                    value="{{ intval($setting->xp_follow_host ?? 0) }}" required>
            </div>
            <div class="mb-3">
                <label for="xp_send_gift_per_diamond" class="form-label">{{ __('Send gift (1 diamond)') }}</label>
                <input class="form-control" type="number" min="0" id="xp_send_gift_per_diamond" name="xp_send_gift_per_diamond"
                    value="{{ intval($setting->xp_send_gift_per_diamond ?? 0) }}" required>
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
