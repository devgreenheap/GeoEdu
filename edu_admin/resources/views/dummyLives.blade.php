@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/dummyLives.js') }}"></script>
@endsection
@section('content')

<div class="mb-2">
</div>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Dummy Lives')}}
        </h4>
        <a data-bs-toggle="modal" data-bs-target="#addDummyLiveModal" class="btn btn-dark ms-auto">{{ __('Add')}}</a>
    </a>
    </div>
    <div class="card-body">
        <span class="fs-6">*Make sure to add links which points directly to video files. Embedded links will not work.</span><br>
        <span class="fs-6">*Links should end with .mp4 or .m3u8</span>
        <div class="table-responsive mt-2">
            <table id="dummyLivesTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3" >
                <thead class="table-light">
                    <tr>
                        <th>{{ __('User')}}</th>
                        <th>{{ __('Category')}}</th>
                        <th>{{ __('Sub Category')}}</th>
                        <th>{{ __('Topic')}}</th>
                        <th>{{ __('Language')}}</th>
                        <th>{{ __('Title')}}</th>
                        <th>{{ __('Video')}}</th>
                        <th>{{ __('Status')}}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action')}}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

{{-- Add Modal --}}
<div id="addDummyLiveModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Dummy Live')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addDummyLiveForm" method="POST">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="title" class="form-label">{{ __('Select Dummy User')}}</label>
                        <select name="user_id" id="" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Dummy User')}}</option>
                            @foreach($dummyUsers as $user)
                            <option value="{{ $user->id }}">{{ $user->fullname }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="category_id" class="form-label">{{ __('Category')}}</label>
                        <select name="category_id" id="dummy_live_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Category')}}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="sub_category_id" class="form-label">{{ __('Sub Category')}}</label>
                        <select name="sub_category_id" id="dummy_live_sub_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Sub Category')}}</option>
                            @foreach($subCategories as $subCategory)
                            <option value="{{ $subCategory->id }}" data-category-id="{{ $subCategory->category_id }}">{{ $subCategory->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="topic_id" class="form-label">{{ __('Topic')}}</label>
                        <select name="topic_id" id="dummy_live_topic_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Topic')}}</option>
                            @foreach($topics as $topic)
                            <option value="{{ $topic->id }}" data-category-id="{{ $topic->category_id }}" data-sub-category-id="{{ $topic->sub_category_id }}">{{ $topic->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="language_id" class="form-label">{{ __('Language')}}</label>
                        <select name="language_id" id="dummy_live_language_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Language')}}</option>
                            @foreach($languages as $language)
                            <option value="{{ $language->id }}">{{ $language->title }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="title" class="form-label">{{ __('Title')}}</label>
                        <input class="form-control" type="text" id="title" name="title" required>
                    </div>
                    <span class="fs-6">*Make sure to add links which points directly to video files. Embedded links will not work.</span><br>
                    <span class="fs-6">*Links should end with .mp4 or .m3u8</span>
                    <div class="mb-2">
                        <label for="link" class="form-label">{{ __('Link')}}</label>
                        <input class="form-control" type="text" id="link" name="link" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close')}}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save')}}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
{{-- edit Modal --}}
<div id="editDummyLiveModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Dummy Live')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editDummyLiveForm" method="POST">
                <input type="hidden" name="id" id="editDummyLiveId">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="edit_dummy_live_category_id" class="form-label">{{ __('Category')}}</label>
                        <select name="category_id" id="edit_dummy_live_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Category')}}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_dummy_live_sub_category_id" class="form-label">{{ __('Sub Category')}}</label>
                        <select name="sub_category_id" id="edit_dummy_live_sub_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Sub Category')}}</option>
                            @foreach($subCategories as $subCategory)
                            <option value="{{ $subCategory->id }}" data-category-id="{{ $subCategory->category_id }}">{{ $subCategory->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_dummy_live_topic_id" class="form-label">{{ __('Topic')}}</label>
                        <select name="topic_id" id="edit_dummy_live_topic_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Topic')}}</option>
                            @foreach($topics as $topic)
                            <option value="{{ $topic->id }}" data-category-id="{{ $topic->category_id }}" data-sub-category-id="{{ $topic->sub_category_id }}">{{ $topic->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_dummy_live_language_id" class="form-label">{{ __('Language')}}</label>
                        <select name="language_id" id="edit_dummy_live_language_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Language')}}</option>
                            @foreach($languages as $language)
                            <option value="{{ $language->id }}">{{ $language->title }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="title" class="form-label">{{ __('Title')}}</label>
                        <input class="form-control" type="text" id="edit_dummy_live_title" name="title" required>
                    </div>
                    <span class="fs-6">*Make sure to add links which points directly to video files. Embedded links will not work.</span><br>
                    <span class="fs-6">*Links should end with .mp4 or .m3u8</span>
                    <div class="mb-2">
                        <label for="link" class="form-label">{{ __('Link')}}</label>
                        <input class="form-control" type="text" id="edit_dummy_live_link" name="link" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close')}}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save')}}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>


@endsection
