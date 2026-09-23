@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/interests.js') }}"></script>
@endsection
@section('content')

<div class="mb-2"></div>

<div class="card">
    <div class="card-body">
        <div class="d-flex align-items-center border-bottom pb-2">
            <h4 class="card-title mb-0 header-title">{{ __('Interests') }}</h4>
            <a data-bs-toggle="modal" data-bs-target="#addInterestModal" class="btn btn-dark ms-auto">{{ __('Add') }}</a>
        </div>
        <div class="table-responsive mt-2">
            <table id="interestsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Interest Name') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="addInterestModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Interest') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addInterestForm" method="POST">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="name" class="form-label">{{ __('Interest Name') }}</label>
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

<div id="editInterestModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Interest') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editInterestForm" method="POST">
                <input type="hidden" name="id" id="editInterestId">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="edit_interest_name" class="form-label">{{ __('Interest Name') }}</label>
                        <input class="form-control" type="text" id="edit_interest_name" name="name" required>
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
