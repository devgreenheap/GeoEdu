@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/diamondPackages.js') }}"></script>
@endsection
@section('content')

<div class="mb-2">
</div>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Diamond Packages')}}
        </h4>
        <a data-bs-toggle="modal" data-bs-target="#addPackageModal" class="btn btn-dark ms-auto">{{ __('Add')}}</a>
    </a>
    </div>
    <div class="card-body">
        <span class="fs-6">*Price is for reference only. Actual price will be fetched from Google/Apple stores in the app based on users location.</span>
        <span class="fs-6">*Please refer documentation to learn how to add new diamond plans.</span>
        <div class="table-responsive mt-2">
            <table id="diamondPackagesTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3" >
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Image')}}</th>
                        <th>{{ __('Diamond Amount')}}</th>
                        <th>{{ __('Price')}}</th>
                        <th>{{ __('Discounted Price')}}</th>
                        <th>{{ __('Offer (Entry Effect)')}}</th>
                        <th>{{ __('Status')}}</th>
                        <th>{{ __('PlayStore Product Id')}}</th>
                        <th>{{ __('AppStore Product Id')}}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action')}}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

{{-- Add Modal --}}
<div id="addPackageModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Package')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addDiamondPackageForm" method="POST">
                <div class="modal-body">
                    <img id="imgAddDiamondPackPreview" src="{{ url('assets/img/placeholder.png')}}" alt="" class="rounded" height="100" width="100">
                    <div class="my-2">
                        <label for="image" class="form-label">{{ __('Image')}}</label>
                        <input id="inputAddDiamondPackImage" class="form-control" type="file" accept="image/*" min="1" id="image" name="image" required>
                    </div>
                    <div class="mb-2">
                        <label for="diamond_amount" class="form-label">{{ __('Diamond Amount')}}</label>
                        <input class="form-control" type="number" min="1" id="diamond_amount" name="diamond_amount" required>
                    </div>
                    <div class="">
                        <label for="diamond_plan_price" class="form-label">{{ __('Price')}}</label>
                        <input class="form-control" type="number" min="1" step="any" id="diamond_plan_price" name="diamond_plan_price" required>
                    </div>
                    <div class="my-2">
                        <label for="discounted_price" class="form-label">{{ __('Discounted Price (Optional)')}}</label>
                        <input class="form-control" type="number" min="0" step="any" id="discounted_price" name="discounted_price">
                    </div>
                    <div class="mb-2">
                        <label for="offer_entry_effect_id" class="form-label">{{ __('Offer (Entry Effect) (Optional)')}}</label>
                        <select class="form-control select2 remove-searchbar" id="offer_entry_effect_id" name="offer_entry_effect_id" data-toggle="select2">
                            <option value="">{{ __('No Offer') }}</option>
                            @foreach($entryEffects as $entryEffect)
                            <option value="{{ $entryEffect->id }}">#{{ $entryEffect->id }} | {{ $entryEffect->title ?? '-' }} | {{ __('Coins') }}: {{ $entryEffect->coin_price }} | {{ __('Duration') }}: {{ $entryEffect->duration }}h</option>
                            @endforeach
                        </select>
                    </div>
                    <span class="fs-6">*Price is for reference only. Actual price will be fetched from Google/Apple stores in the app based on users location.</span>
                    <div class="my-2">
                        <label for="playstore_product_id" class="form-label">{{ __('PlayStore Product Id')}}</label>
                        <input class="form-control" type="text" id="playstore_product_id" name="playstore_product_id" required>
                    </div>
                    <div class="mb-2">
                        <label for="appstore_product_id" class="form-label">{{ __('AppStore Product Id')}}</label>
                        <input class="form-control" type="text" id="appstore_product_id" name="appstore_product_id" required>
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
{{-- Edit Modal --}}
<div id="editPackageModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Package')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editDiamondPackageForm" method="POST">
                <input type="hidden" name="id" id="editDiamondPackageId">
                <div class="modal-body">
                    <img id="imgEditDiamondPackPreview" src="{{ url('assets/img/placeholder.png')}}" alt="" class="rounded" height="100" width="100">
                    <div class="my-2">
                        <label for="image" class="form-label">{{ __('Image')}}</label>
                        <input id="inputEditDiamondPackImage" class="form-control" type="file" accept="image/*" min="1" name="image">
                    </div>
                    <div class="mb-2">
                        <label for="diamond_amount" class="form-label">{{ __('Diamond Amount')}}</label>
                        <input class="form-control" type="number" min="1" id="edit_diamond_amount" name="diamond_amount" required>
                    </div>
                    <div class="">
                        <label for="diamond_plan_price" class="form-label">{{ __('Price')}}</label>
                        <input class="form-control" type="number" min="1" step="any" id="edit_diamond_plan_price" name="diamond_plan_price" required>
                    </div>
                    <div class="my-2">
                        <label for="edit_discounted_price" class="form-label">{{ __('Discounted Price (Optional)')}}</label>
                        <input class="form-control" type="number" min="0" step="any" id="edit_discounted_price" name="discounted_price">
                    </div>
                    <div class="mb-2">
                        <label for="edit_offer_entry_effect_id" class="form-label">{{ __('Offer (Entry Effect) (Optional)')}}</label>
                        <select class="form-control select2 remove-searchbar" id="edit_offer_entry_effect_id" name="offer_entry_effect_id" data-toggle="select2">
                            <option value="">{{ __('No Offer') }}</option>
                            @foreach($entryEffects as $entryEffect)
                            <option value="{{ $entryEffect->id }}">#{{ $entryEffect->id }} | {{ $entryEffect->title ?? '-' }} | {{ __('Coins') }}: {{ $entryEffect->coin_price }} | {{ __('Duration') }}: {{ $entryEffect->duration }}h</option>
                            @endforeach
                        </select>
                    </div>
                    <span class="fs-6">*Price is for reference only. Actual price will be fetched from Google/Apple stores in the app based on users location.</span>
                    <div class="my-2">
                        <label for="playstore_product_id" class="form-label">{{ __('PlayStore Product Id')}}</label>
                        <input class="form-control" type="text" id="edit_playstore_product_id" name="playstore_product_id" required>
                    </div>
                    <div class="mb-2">
                        <label for="appstore_product_id" class="form-label">{{ __('AppStore Product Id')}}</label>
                        <input class="form-control" type="text" id="edit_appstore_product_id" name="appstore_product_id" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close')}}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Submit')}}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
