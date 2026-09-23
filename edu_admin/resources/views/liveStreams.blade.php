@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/liveStreams.js') }}"></script>
@endsection
@section('content')
<style>
    .live-filter-panel {
        border: 1px solid #e7eaf0;
        border-radius: 12px;
        background: #f9fbff;
        padding: 16px;
        margin-bottom: 14px;
    }

    .live-filter-label {
        font-size: 12px;
        font-weight: 600;
        color: #475467;
        margin-bottom: 6px;
    }

    .live-filter-panel .form-control {
        height: 40px;
        border-radius: 8px;
        min-width: 0;
    }

    .live-filter-actions {
        display: flex;
        gap: 10px;
        flex-wrap: wrap;
        justify-content: flex-end;
        align-items: flex-end;
    }

    .live-filter-actions .btn {
        min-width: 120px;
    }

    @media (max-width: 991.98px) {
        .live-filter-actions {
            justify-content: flex-start;
        }
    }

    @media (max-width: 767.98px) {
        .live-filter-panel {
            padding: 12px;
        }

        .live-filter-actions {
            justify-content: flex-start;
        }

        .live-filter-actions .btn {
            flex: 1 1 calc(50% - 5px);
            min-width: 0;
            padding-inline: 12px !important;
        }
    }

    @media (max-width: 479.98px) {
        .live-filter-actions .btn {
            flex-basis: 100%;
        }
    }
</style>

<div class="mb-2"></div>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Live Streams') }}
        </h4>
    </div>
    <div class="card-body">
        <div class="live-filter-panel">
            <div class="row g-3 align-items-end">
                <div class="col-12 col-md-6 col-lg-2">
                    <label for="filter_date" class="form-label live-filter-label">{{ __('Date') }}</label>
                    <input type="date" id="filter_date" class="form-control">
                </div>
                <div class="col-12 col-md-6 col-lg-2">
                    <label for="filter_category_id" class="form-label live-filter-label">{{ __('Category') }}</label>
                    <select id="filter_category_id" class="form-control">
                        <option value="">{{ __('All') }}</option>
                        @foreach($categories as $category)
                        <option value="{{ $category->id }}">{{ $category->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12 col-md-6 col-lg-2">
                    <label for="filter_sub_category_id" class="form-label live-filter-label">{{ __('Sub Category') }}</label>
                    <select id="filter_sub_category_id" class="form-control">
                        <option value="">{{ __('All') }}</option>
                        @foreach($subCategories as $subCategory)
                        <option value="{{ $subCategory->id }}" data-category-id="{{ $subCategory->category_id }}">{{ $subCategory->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12 col-md-6 col-lg-2">
                    <label for="filter_topic_id" class="form-label live-filter-label">{{ __('Topic') }}</label>
                    <select id="filter_topic_id" class="form-control">
                        <option value="">{{ __('All') }}</option>
                        @foreach($topics as $topic)
                        <option value="{{ $topic->id }}" data-sub-category-id="{{ $topic->sub_category_id }}">{{ $topic->name }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12 col-md-6 col-lg-2">
                    <label for="filter_language_id" class="form-label live-filter-label">{{ __('Language') }}</label>
                    <select id="filter_language_id" class="form-control">
                        <option value="">{{ __('All') }}</option>
                        @foreach($languages as $language)
                        <option value="{{ $language->id }}">{{ $language->title ?? $language->code }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12 col-md-6 col-lg-2">
                    <label for="filter_user_id" class="form-label live-filter-label">{{ __('User') }}</label>
                    <select id="filter_user_id" class="form-control">
                        <option value="">{{ __('All') }}</option>
                        @foreach($users as $user)
                        <option value="{{ $user->id }}">{{ $user->username }}{{ !empty($user->fullname) ? (' - ' . $user->fullname) : '' }}</option>
                        @endforeach
                    </select>
                </div>
                <div class="col-12 live-filter-actions mt-1">
                    <button type="button" id="applyLiveStreamFilters" class="btn btn-primary px-4">{{ __('Apply Filters') }}</button>
                    <button type="button" id="resetLiveStreamFilters" class="btn btn-light px-4">{{ __('Reset') }}</button>
                </div>
            </div>
        </div>
        <div class="table-responsive mt-2">
            <table id="liveStreamsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Stream ID') }}</th>
                        <th>{{ __('User') }}</th>
                        <th>{{ __('Title') }}</th>
                        <th>{{ __('Category Details') }}</th>
                        <th>{{ __('Started At') }}</th>
                        <th>{{ __('Ended At') }}</th>
                        <th>{{ __('Duration (sec)') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th style="width: 220px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
