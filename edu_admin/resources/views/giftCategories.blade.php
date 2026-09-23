@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/giftCategories.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('Gift Categories') }}</h4>
        <a data-bs-toggle="modal" data-bs-target="#addGiftCategoryModal" class="btn btn-dark ms-auto">{{ __('Add Gift Category') }}</a>
    </div>
    <div class="card-body">
        <div id="gift-category-list" class="row">
            @foreach ($categories as $category)
                <div class="col-md-2">
                    <div class="card gift-card text-center">
                        <div class="card-body">
                            <div class="gift-img">
                                <img src="{{ \App\Models\GlobalFunction::generateFileUrl($category->image) ?: ($baseUrl . $category->image) }}" onerror="this.onerror=null;this.src='{{ asset('assets/img/placeholder.png') }}';" alt="" class="img-fluid">
                            </div>
                            <h5>{{ $category->name }}</h5>
                            <div class="gift-card-action">
                                <div class="d-flex justify-content-center align-items-center">
                                    <a href="#" data-imageurl="{{ \App\Models\GlobalFunction::generateFileUrl($category->image) ?: ($baseUrl . $category->image) }}" data-name="{{ $category->name }}" rel="{{ $category->id }}" class="action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1">
                                        <i class="uil-pen"></i>
                                    </a>
                                    <a href="#" rel="{{ $category->id }}" class="action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1">
                                        <i class='uil-trash-alt'></i>
                                    </a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            @endforeach
        </div>
    </div>
</div>

<div id="addGiftCategoryModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add Gift Category') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addGiftCategoryForm" method="POST">
                <div class="modal-body">
                    <img id="imgAddGiftCategoryPreview" src="{{ url('assets/img/placeholder.png') }}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="addGiftCategoryImage" class="form-label">{{ __('Image') }}</label>
                        <input id="addGiftCategoryImage" class="form-control" type="file" accept="image/*,.svg" name="image" required>
                    </div>
                    <div class="mb-3">
                        <label for="addGiftCategoryName" class="form-label">{{ __('Name') }}</label>
                        <input id="addGiftCategoryName" class="form-control" type="text" name="name" required>
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

<div id="editGiftCategoryModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit Gift Category') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editGiftCategoryForm" method="POST">
                <input type="hidden" name="id" id="editGiftCategoryId">
                <div class="modal-body">
                    <img id="imgEditGiftCategoryPreview" src="{{ url('assets/img/placeholder.png') }}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="editGiftCategoryImage" class="form-label">{{ __('Image') }} ({{ __('Select To Edit Only') }})</label>
                        <input id="editGiftCategoryImage" class="form-control" type="file" accept="image/*,.svg" name="image">
                    </div>
                    <div class="mb-3">
                        <label for="editGiftCategoryName" class="form-label">{{ __('Name') }}</label>
                        <input id="editGiftCategoryName" class="form-control" type="text" name="name" required>
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

