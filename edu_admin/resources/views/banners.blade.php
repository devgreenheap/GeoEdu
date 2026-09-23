@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/banners.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('Banners') }}</h4>
        <a data-bs-toggle="modal" data-bs-target="#addBannerModal" class="btn btn-dark ms-auto">{{ __('Add Banner') }}</a>
    </div>
    <div class="card-body">
        <div id="banner-list" class="row">
            @foreach ($items as $item)
                <div class="col-md-2">
                    <div class="card gift-card text-center">
                        <div class="card-body">
                            <div class="gift-img">
                                <img src="{{ $baseUrl }}{{ $item->image }}" alt="" class="img-fluid">
                            </div>
                            <h5 class="text-capitalize">{{ $item->type }}</h5>
                            <div class="gift-card-action">
                                <div class="d-flex justify-content-center align-items-center">
                                    <a href="#" data-imageurl="{{ $baseUrl }}{{ $item->image }}" data-type="{{ $item->type }}" rel="{{ $item->id }}" class="action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1">
                                        <i class="uil-pen"></i>
                                    </a>
                                    <a href="#" rel="{{ $item->id }}" class="action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1">
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

<div id="addBannerModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add Banner') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addBannerForm" method="POST">
                <div class="modal-body">
                    <img id="imgAddBannerPreview" src="{{ url('assets/img/placeholder.png') }}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="addBannerImage" class="form-label">{{ __('Image') }}</label>
                        <input id="addBannerImage" class="form-control" type="file" accept="image/*" name="image" required>
                    </div>
                    <div class="mb-3">
                        <label for="addBannerType" class="form-label">{{ __('Type Of Banner') }}</label>
                        <select id="addBannerType" class="form-control" name="type" required>
                            <option value="">{{ __('Select Type') }}</option>
                            <option value="audio">{{ __('Audio') }}</option>
                            <option value="homepage">{{ __('Homepage') }}</option>
                        </select>
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

<div id="editBannerModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit Banner') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editBannerForm" method="POST">
                <input type="hidden" name="id" id="editBannerId">
                <div class="modal-body">
                    <img id="imgEditBannerPreview" src="{{ url('assets/img/placeholder.png') }}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="editBannerImage" class="form-label">{{ __('Image') }} ({{ __('Select To Edit Only') }})</label>
                        <input id="editBannerImage" class="form-control" type="file" accept="image/*" name="image">
                    </div>
                    <div class="mb-3">
                        <label for="editBannerType" class="form-label">{{ __('Type Of Banner') }}</label>
                        <select id="editBannerType" class="form-control" name="type" required>
                            <option value="">{{ __('Select Type') }}</option>
                            <option value="audio">{{ __('Audio') }}</option>
                            <option value="homepage">{{ __('Homepage') }}</option>
                        </select>
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
