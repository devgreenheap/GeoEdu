@extends('include.app')

@section('script')
<script src="{{ asset('assets/script/categoryDetails.js') }}"></script>
@endsection

@section('content')
<ul class="nav nav-tabs mb-3" role="tablist">
    <li class="nav-item" role="presentation">
        <a class="nav-link active category-details-tab" data-bs-toggle="tab" href="#categories-tab" role="tab" data-url="{{ url('categories') }}?embed=1">
            {{ __('Categories') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link category-details-tab" data-bs-toggle="tab" href="#sub-categories-tab" role="tab" data-url="{{ url('categories') }}?tab=sub-category&embed=1">
            {{ __('Sub Categories') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link category-details-tab" data-bs-toggle="tab" href="#topics-tab" role="tab" data-url="{{ url('topics') }}?embed=1">
            {{ __('Topics') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link category-details-tab" data-bs-toggle="tab" href="#hashtags-tab" role="tab" data-url="{{ url('hashtags') }}?embed=1">
            {{ __('Hashtags') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link category-details-tab" data-bs-toggle="tab" href="#countries-tab" role="tab" data-url="{{ url('countries') }}?embed=1">
            {{ __('Country List') }}
        </a>
    </li>
    <li class="nav-item" role="presentation">
        <a class="nav-link category-details-tab" data-bs-toggle="tab" href="#states-master-tab" role="tab" data-url="{{ url('statesMaster') }}?embed=1">
            {{ __('State List') }}
        </a>
    </li>
</ul>

<div class="tab-content">
    <div class="tab-pane fade show active" id="categories-tab" role="tabpanel">
        <iframe id="category-details-frame-categories-tab" class="w-100 border rounded-2 category-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="sub-categories-tab" role="tabpanel">
        <iframe id="category-details-frame-sub-categories-tab" class="w-100 border rounded-2 category-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="topics-tab" role="tabpanel">
        <iframe id="category-details-frame-topics-tab" class="w-100 border rounded-2 category-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="hashtags-tab" role="tabpanel">
        <iframe id="category-details-frame-hashtags-tab" class="w-100 border rounded-2 category-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="countries-tab" role="tabpanel">
        <iframe id="category-details-frame-countries-tab" class="w-100 border rounded-2 category-details-frame" data-loaded="0"></iframe>
    </div>
    <div class="tab-pane fade" id="states-master-tab" role="tabpanel">
        <iframe id="category-details-frame-states-master-tab" class="w-100 border rounded-2 category-details-frame" data-loaded="0"></iframe>
    </div>
</div>
@endsection
