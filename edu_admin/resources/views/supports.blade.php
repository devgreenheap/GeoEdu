@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/supports.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('Support Requests') }}</h4>
        <select id="supportStatusFilter" class="form-select w-auto ms-auto">
            <option value="">{{ __('All Statuses') }}</option>
            <option value="open">{{ __('Open') }}</option>
            <option value="answered">{{ __('Answered') }}</option>
            <option value="closed">{{ __('Closed') }}</option>
        </select>
    </div>
    <div class="card-body">
        <span class="fs-6">*Users can create support tickets from the app. Admin can reply, close, and reopen them here.</span>
        <div class="table-responsive mt-2">
            <table id="supportsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('User') }}</th>
                        <th>{{ __('Request') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th>{{ __('Created At') }}</th>
                        <th style="width: 220px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="replySupportModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Reply To Support') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="replySupportForm" method="POST">
                <input type="hidden" name="id" id="replySupportId">
                <div class="modal-body">
                    <div class="mb-2">
                        <label class="form-label">{{ __('Subject') }}</label>
                        <input type="text" id="replySupportSubject" class="form-control" readonly>
                    </div>
                    <div class="mb-2">
                        <label class="form-label">{{ __('Message') }}</label>
                        <textarea id="replySupportMessage" rows="5" class="form-control" readonly></textarea>
                    </div>
                    <div class="mb-2">
                        <label for="replySupportText" class="form-label">{{ __('Admin Reply') }}</label>
                        <textarea id="replySupportText" name="admin_reply" rows="6" class="form-control" required></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save Reply') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
