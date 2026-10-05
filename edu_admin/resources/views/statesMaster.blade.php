@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/statesMaster.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('State List') }}</h4>
        <div class="ms-auto d-flex align-items-center gap-2">
            <button type="button" data-bs-toggle="modal" data-bs-target="#importStateModal" class="btn btn-outline-success">
                <i class="ri-file-excel-2-line me-1"></i>{{ __('Import Excel') }}
            </button>
            <a data-bs-toggle="modal" data-bs-target="#addStateModal" class="btn btn-dark">{{ __('Add State') }}</a>
        </div>
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

{{-- Import State Modal --}}
<div id="importStateModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="importStateModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="importStateModalLabel">
                    <i class="ri-file-excel-2-line text-success me-1"></i> {{ __('Import States via Excel / CSV') }}
                </h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="importStateForm" method="POST" enctype="multipart/form-data">
                <div class="modal-body">
                    <div class="alert alert-info border-0 mb-3" role="alert">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <span class="fw-semibold"><i class="ri-information-line me-1"></i>{{ __('Instructions') }}</span>
                            <a href="{{ route('downloadImportSample', ['type' => 'states']) }}" class="btn btn-xs btn-primary text-white">
                                <i class="ri-download-2-line me-1"></i>{{ __('Download Sample') }}
                            </a>
                        </div>
                        <small class="text-muted d-block">
                            {{ __('Supported formats: .xlsx, .xls, .csv. Columns required:') }} <strong>Country Name, State Name</strong>.
                        </small>
                    </div>

                    <div class="mb-3">
                        <label for="state_excel_file" class="form-label fw-bold">{{ __('Select File') }} <span class="text-danger">*</span></label>
                        <input type="file" id="state_excel_file" name="file" class="form-control" accept=".xlsx,.xls,.csv" required>
                        <div class="form-text text-muted">{{ __('Maximum file size: 10MB') }}</div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-success">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        <i class="ri-upload-cloud-2-line me-1"></i>{{ __('Upload & Import') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
