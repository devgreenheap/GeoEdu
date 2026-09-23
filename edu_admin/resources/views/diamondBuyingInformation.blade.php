@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/diamondBuyingInformation.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Diamond Buying Information') }}
        </h4>
        <a data-bs-toggle="modal" data-bs-target="#addDiamondBuyingInformationModal" class="btn btn-dark ms-auto">{{ __('Add Information') }}</a>
    </div>
    <div class="card-body">
        <div id="diamond-buying-information-list" class="row g-3">
            @forelse ($items as $index => $item)
            <div class="col-md-6 col-lg-4">
                <div class="card border h-100 mb-0">
                    <div class="card-body">
                        <h5 class="mb-2">{{ __('Point') }} {{ $index + 1 }}</h5>
                        <p class="mb-3">{{ $item->information }}</p>
                        <div class="d-flex justify-content-end align-items-center">
                            <a href="#"
                                rel="{{ $item->id }}"
                                data-information="{{ $item->information }}"
                                class="action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1">
                                <i class="uil-pen"></i>
                            </a>
                            <a href="#"
                                rel="{{ $item->id }}"
                                class="action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1">
                                <i class='uil-trash-alt'></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
            @empty
            <div class="col-12">
                <p class="text-muted mb-0">{{ __('No information added yet.') }}</p>
            </div>
            @endforelse
        </div>
    </div>
</div>

<div id="addDiamondBuyingInformationModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add Information') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addDiamondBuyingInformationForm" method="POST">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="information" class="form-label">{{ __('Information') }}</label>
                        <textarea class="form-control" id="information" name="information" rows="4" required></textarea>
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

<div id="editDiamondBuyingInformationModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit Information') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editDiamondBuyingInformationForm" method="POST">
                <input type="hidden" name="id" id="editDiamondBuyingInformationId">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="edit_information" class="form-label">{{ __('Information') }}</label>
                        <textarea class="form-control" id="edit_information" name="information" rows="4" required></textarea>
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

