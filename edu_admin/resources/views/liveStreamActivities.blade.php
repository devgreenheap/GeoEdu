@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/liveStreamActivities.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <div>
            <h4 class="card-title mb-0 header-title">{{ __('Live Stream Activities') }}</h4>
            <p class="mb-0 mt-1 text-muted">
                {{ __('Stream ID') }}: #{{ $stream->id }} | {{ __('Title') }}: {{ $stream->title ?? '-' }}
            </p>
        </div>
        <a href="{{ url('liveStreams') }}" class="btn btn-dark ms-auto">{{ __('Back') }}</a>
    </div>
    <div class="card-body">
        <input type="hidden" id="live_stream_id" value="{{ $stream->id }}">
        <div class="table-responsive mt-2">
            <table id="liveStreamActivitiesTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('ID') }}</th>
                        <th>{{ __('Type') }}</th>
                        <th>{{ __('Sender') }}</th>
                        <th>{{ __('Receiver') }}</th>
                        <th>{{ __('Comment') }}</th>
                        <th>{{ __('Gift') }}</th>
                        <th>{{ __('Created At') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
