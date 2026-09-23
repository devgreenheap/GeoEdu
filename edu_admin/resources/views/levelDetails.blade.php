@extends('include.app')

@section('script')
<script src="{{ asset('assets/script/levelDetails.js') }}"></script>
@endsection

@section('content')
<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link active level-details-tab" data-bs-toggle="tab" href="#levels-tab" role="tab" data-url="{{ url('levels') }}?embed=1">
            {{ __('Level') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link level-details-tab" data-bs-toggle="tab" href="#level-badges-tab" role="tab" data-url="{{ url('levelBadges') }}?embed=1">
            {{ __('Level Badges') }}
        </a>
    </li>
</ul>

<div class="tab-content">
    <div class="tab-pane fade show active" id="levels-tab" role="tabpanel">
        <iframe id="level-details-frame-levels-tab" class="w-100 border rounded-2 level-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="level-badges-tab" role="tabpanel">
        <iframe id="level-details-frame-level-badges-tab" class="w-100 border rounded-2 level-details-frame" data-loaded="0"></iframe>
    </div>
</div>
@endsection
