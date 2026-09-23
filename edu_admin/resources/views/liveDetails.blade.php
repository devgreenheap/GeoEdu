@extends('include.app')

@section('script')
<script src="{{ asset('assets/script/liveDetails.js') }}"></script>
@endsection

@section('content')
<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link active live-details-tab" data-bs-toggle="tab" href="#live-streams-tab" role="tab" data-url="{{ url('liveStreams') }}?embed=1">
            {{ __('Live Streams') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link live-details-tab" data-bs-toggle="tab" href="#chat-tab" role="tab" data-url="{{ url('firebaseChats') }}?embed=1">
            {{ __('Chat') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link live-details-tab" data-bs-toggle="tab" href="#audio-tab" role="tab" data-url="{{ url('firebaseAudioRooms') }}?embed=1">
            {{ __('Audio Details') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link live-details-tab" data-bs-toggle="tab" href="#pk-battle-tab" role="tab" data-url="{{ url('firebasePkBattles') }}?embed=1">
            {{ __('PK Battle') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link live-details-tab" data-bs-toggle="tab" href="#dummy-lives-tab" role="tab" data-url="{{ url('dummyLives') }}?embed=1">
            {{ __('Dummy Lives') }}
        </a>
    </li>
</ul>

<div class="tab-content">
    <div class="tab-pane fade show active" id="live-streams-tab" role="tabpanel">
        <iframe id="live-details-frame-live-streams-tab" class="w-100 border rounded-2 live-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="chat-tab" role="tabpanel">
        <iframe id="live-details-frame-chat-tab" class="w-100 border rounded-2 live-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="audio-tab" role="tabpanel">
        <iframe id="live-details-frame-audio-tab" class="w-100 border rounded-2 live-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="pk-battle-tab" role="tabpanel">
        <iframe id="live-details-frame-pk-battle-tab" class="w-100 border rounded-2 live-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="dummy-lives-tab" role="tabpanel">
        <iframe id="live-details-frame-dummy-lives-tab" class="w-100 border rounded-2 live-details-frame" data-loaded="0"></iframe>
    </div>
</div>
@endsection
