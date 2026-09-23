@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/categories.js') }}"></script>
@endsection
@section('content')
@php
    $isSubCategoryTab = request()->get('tab') === 'sub-category';
    $isEmbedView = request()->boolean('embed');
@endphp

<div class="mb-2"></div>

<div class="card">
    <div class="card-body">
        <div class="row">
            @if(!$isEmbedView)
            <div class="col-sm-3 mb-2 mb-sm-0">
                <div class="nav nav-pills" id="v-pills-tab" role="tablist" aria-orientation="vertical">
                    <a class="nav-link {{ $isSubCategoryTab ? '' : 'active show' }}" id="v-pills-category-tab" data-bs-toggle="pill" href="#v-pills-category" role="tab" aria-controls="v-pills-category" aria-selected="{{ $isSubCategoryTab ? 'false' : 'true' }}">
                        <span class="d-md-block">{{ __('Categories') }}</span>
                    </a>
                    <a class="nav-link {{ $isSubCategoryTab ? 'active show' : '' }}" id="v-pills-sub-category-tab" data-bs-toggle="pill" href="#v-pills-sub-category" role="tab" aria-controls="v-pills-sub-category" aria-selected="{{ $isSubCategoryTab ? 'true' : 'false' }}">
                        <span class="d-md-block">{{ __('Sub Categories') }}</span>
                    </a>
                </div>
            </div>
            @endif

            <div class="col-sm-12">
                <div class="tab-content mt-3" id="v-pills-tabContent">
                    <div class="tab-pane fade {{ $isSubCategoryTab ? '' : 'active show' }}" id="v-pills-category" role="tabpanel" aria-labelledby="v-pills-category-tab">
                        <div class="d-flex align-items-center border-bottom pb-2">
                            <h4 class="card-title mb-0 header-title">{{ __('Categories') }}</h4>
                            <a data-bs-toggle="modal" data-bs-target="#addCategoryModal" class="btn btn-dark ms-auto">{{ __('Add') }}</a>
                        </div>
                        <div class="table-responsive mt-2">
                            <table id="categoriesTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                                <thead class="table-light">
                                    <tr>
                                        <th>{{ __('Category Name') }}</th>
                                        <th>{{ __('Status') }}</th>
                                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>

                    <div class="tab-pane fade {{ $isSubCategoryTab ? 'active show' : '' }}" id="v-pills-sub-category" role="tabpanel" aria-labelledby="v-pills-sub-category-tab">
                        <div class="d-flex align-items-center border-bottom pb-2">
                            <h4 class="card-title mb-0 header-title">{{ __('Sub Categories') }}</h4>
                            <a data-bs-toggle="modal" data-bs-target="#addSubCategoryModal" class="btn btn-dark ms-auto">{{ __('Add') }}</a>
                        </div>
                        <div class="table-responsive mt-2">
                            <table id="subCategoriesTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                                <thead class="table-light">
                                    <tr>
                                        <th>{{ __('Category') }}</th>
                                        <th>{{ __('Sub Category') }}</th>
                                        <th>{{ __('Status') }}</th>
                                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<div id="addCategoryModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Category') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addCategoryForm" method="POST">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="name" class="form-label">{{ __('Category Name') }}</label>
                        <input class="form-control" type="text" id="name" name="name" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="editCategoryModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Category') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editCategoryForm" method="POST">
                <input type="hidden" name="id" id="editCategoryId">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="edit_category_name" class="form-label">{{ __('Category Name') }}</label>
                        <input class="form-control" type="text" id="edit_category_name" name="name" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="addSubCategoryModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Sub Category') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addSubCategoryForm" method="POST">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="sub_category_category_id" class="form-label">{{ __('Category') }}</label>
                        <select name="category_id" id="sub_category_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Category') }}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="sub_category_name" class="form-label">{{ __('Sub Category') }}</label>
                        <input class="form-control" type="text" id="sub_category_name" name="name" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="editSubCategoryModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Sub Category') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editSubCategoryForm" method="POST">
                <input type="hidden" name="id" id="editSubCategoryId">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="edit_sub_category_category_id" class="form-label">{{ __('Category') }}</label>
                        <select name="category_id" id="edit_sub_category_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Category') }}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_sub_category_name" class="form-label">{{ __('Sub Category') }}</label>
                        <input class="form-control" type="text" id="edit_sub_category_name" name="name" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
