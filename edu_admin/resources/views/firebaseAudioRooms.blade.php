@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/firebaseAudioRooms.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('Firebase Audio Room Details') }}</h4>
    </div>
    <div class="card-body">
        <div class="live-filter-panel mb-3">
            <div class="row g-3 align-items-end">
                <div class="col-12 col-md-4">
                    <label for="filter_audio_room_active" class="form-label">{{ __('Status') }}</label>
                    <select id="filter_audio_room_active" class="form-select">
                        <option value="">{{ __('All') }}</option>
                        <option value="1">{{ __('Live') }}</option>
                        <option value="0">{{ __('Ended') }}</option>
                    </select>
                </div>
                <div class="col-12 col-md-4">
                    <label for="filter_audio_room_host" class="form-label">{{ __('Host (ID/Name)') }}</label>
                    <input type="text" id="filter_audio_room_host" class="form-control" placeholder="{{ __('Search host') }}">
                </div>
                <div class="col-12 col-md-4 d-flex gap-2 justify-content-md-end">
                    <button type="button" id="applyFirebaseAudioRoomFilters" class="btn btn-primary">{{ __('Apply Filters') }}</button>
                    <button type="button" id="resetFirebaseAudioRoomFilters" class="btn btn-light">{{ __('Reset') }}</button>
                </div>
            </div>
        </div>
        <div class="table-responsive mt-2">
            <table id="firebaseAudioRoomsTable" class="table table-centered table-hover w-100 dt-responsive mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Room ID') }}</th>
                        <th>{{ __('Host ID') }}</th>
                        <th>{{ __('Host Name') }}</th>
                        <th>{{ __('Room Name') }}</th>
                        <th>{{ __('Language') }}</th>
                        <th>{{ __('Max Participants') }}</th>
                        <th>{{ __('Participants') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th>{{ __('Created At') }}</th>
                        <th>{{ __('Raw') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
