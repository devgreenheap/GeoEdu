@extends('include.app')

@section('script')
<script src="{{ asset('assets/script/giftDetails.js') }}"></script>
@endsection

@section('content')
<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link active gift-details-tab" data-bs-toggle="tab" href="#gifts-tab" role="tab" data-url="{{ url('gifts') }}?embed=1">
            {{ __('Gifts') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link gift-details-tab" data-bs-toggle="tab" href="#gift-categories-tab" role="tab" data-url="{{ url('giftCategories') }}?embed=1">
            {{ __('Gift Categories') }}
        </a>
    </li>
</ul>

<div class="tab-content">
    <div class="tab-pane fade show active" id="gifts-tab" role="tabpanel">
        <iframe id="gift-details-frame-gifts-tab" class="w-100 border rounded-2 gift-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="gift-categories-tab" role="tabpanel">
        <iframe id="gift-details-frame-gift-categories-tab" class="w-100 border rounded-2 gift-details-frame" data-loaded="0"></iframe>
    </div>
</div>
@endsection
