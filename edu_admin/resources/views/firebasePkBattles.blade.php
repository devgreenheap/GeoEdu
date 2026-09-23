@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/firebasePkBattles.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('PK Battle') }}</h4>
    </div>
    <div class="card-body">
        <div class="table-responsive mt-2">
            <table id="firebasePkBattlesTable" class="table table-centered table-hover w-100 dt-responsive mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Battle ID') }}</th>
                        <th>{{ __('Room ID') }}</th>
                        <th>{{ __('Category') }}</th>
                        <th>{{ __('Language') }}</th>
                        <th>{{ __('Battle Type') }}</th>
                        <th>{{ __('Watching') }}</th>
                        <th>{{ __('Likes') }}</th>
                        <th>{{ __('Host') }}</th>
                        <th>{{ __('Host Coins') }}</th>
                        <th>{{ __('Opponent') }}</th>
                        <th>{{ __('Co-host Coins') }}</th>
                        <th>{{ __('Winner') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th>{{ __('Start Time') }}</th>
                        <th>{{ __('End Time') }}</th>
                        <th>{{ __('Raw') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
