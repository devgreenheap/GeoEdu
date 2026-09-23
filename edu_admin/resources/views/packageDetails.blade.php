@extends('include.app')

@section('script')
<script src="{{ asset('assets/script/packageDetails.js') }}"></script>
@endsection

@section('content')
<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link active package-details-tab" data-bs-toggle="tab" href="#diamond-package-tab" role="tab" data-url="{{ url('diamondPackages') }}?embed=1">
            {{ __('Diamond Package') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link package-details-tab" data-bs-toggle="tab" href="#diamond-buying-info-tab" role="tab" data-url="{{ url('diamondBuyingInformation') }}?embed=1">
            {{ __('Diamond Buying Info') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link package-details-tab" data-bs-toggle="tab" href="#diamond-faq-tab" role="tab" data-url="{{ url('diamondFaqs') }}?embed=1">
            {{ __('FAQ') }}
        </a>
    </li>
</ul>

<div class="tab-content">
    <div class="tab-pane fade show active" id="diamond-package-tab" role="tabpanel">
        <iframe id="package-details-frame-diamond-package-tab" class="w-100 border rounded-2 package-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="diamond-buying-info-tab" role="tabpanel">
        <iframe id="package-details-frame-diamond-buying-info-tab" class="w-100 border rounded-2 package-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="diamond-faq-tab" role="tabpanel">
        <iframe id="package-details-frame-diamond-faq-tab" class="w-100 border rounded-2 package-details-frame" data-loaded="0"></iframe>
    </div>
</div>
@endsection
