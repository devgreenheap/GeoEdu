@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/statesMaster.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('State List') }}</h4>
        <a data-bs-toggle="modal" data-bs-target="#addStateModal" class="btn btn-dark ms-auto">{{ __('Add State') }}</a>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table id="statesMasterTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Country') }}</th>
                        <th>{{ __('State') }}</th>
                        <th style="width: 180px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="addStateModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add State') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addStateForm" method="POST">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="state_country_id" class="form-label">{{ __('Country') }}</label>
                        <select class="form-control" id="state_country_id" name="country_id" required>
                            <option value="">{{ __('Select Country') }}</option>
                            @foreach($countries as $country)
                            <option value="{{ $country->id }}">{{ $country->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="mb-2">
                        <label for="state_name" class="form-label">{{ __('State') }}</label>
                        <input class="form-control" id="state_name" name="name" required>
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

<div id="editStateModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit State') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editStateForm" method="POST">
                <input type="hidden" id="edit_state_id" name="id">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="edit_state_country_id" class="form-label">{{ __('Country') }}</label>
                        <select class="form-control" id="edit_state_country_id" name="country_id" required>
                            <option value="">{{ __('Select Country') }}</option>
                            @foreach($countries as $country)
                            <option value="{{ $country->id }}">{{ $country->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="mb-2">
                        <label for="edit_state_name" class="form-label">{{ __('State') }}</label>
                        <input class="form-control" id="edit_state_name" name="name" required>
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
