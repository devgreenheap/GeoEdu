@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/divisions.js') }}?v={{ @filemtime(public_path('assets/script/divisions.js')) }}"></script>
@endsection
@section('content')
@php
    $isEmbedView = request()->boolean('embed');
@endphp

<div class="mb-2"></div>

<div class="card">
    <div class="card-body">
        <div class="d-flex align-items-center border-bottom pb-2">
            <h4 class="card-title mb-0 header-title">{{ __('Divisions') }}</h4>
            <div class="ms-auto d-flex align-items-center gap-2">
                <button type="button" data-bs-toggle="modal" data-bs-target="#importDivisionModal" class="btn btn-outline-success">
                    <i class="ri-file-excel-2-line me-1"></i>{{ __('Import Excel') }}
                </button>
                <a data-bs-toggle="modal" data-bs-target="#addDivisionModal" class="btn btn-dark">{{ __('Add') }}</a>
            </div>
        </div>
        <div class="table-responsive mt-2">
            <table id="divisionsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Category') }}</th>
                        <th>{{ __('Sub Category') }}</th>
                        <th>{{ __('Division') }}</th>
                        <th>{{ __('Created At') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

{{-- Add Division Modal --}}
<div id="addDivisionModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="addDivisionModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="addDivisionModalLabel">{{ __('Add Division') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addDivisionForm" method="POST">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="division_category_id" class="form-label">{{ __('Category') }}</label>
                        <select name="category_id" id="division_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Category') }}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="division_sub_category_id" class="form-label">{{ __('Sub Category') }}</label>
                        <select name="sub_category_id" id="division_sub_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Sub Category') }}</option>
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="division_name" class="form-label">{{ __('Division Name') }}</label>
                        <input class="form-control" type="text" id="division_name" name="name" required>
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

{{-- Edit Division Modal --}}
<div id="editDivisionModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="editDivisionModalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="editDivisionModalLabel">{{ __('Edit Division') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editDivisionForm" method="POST">
                <input type="hidden" name="id" id="editDivisionId">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="edit_division_category_id" class="form-label">{{ __('Category') }}</label>
                        <select name="category_id" id="edit_division_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Category') }}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_division_sub_category_id" class="form-label">{{ __('Sub Category') }}</label>
                        <select name="sub_category_id" id="edit_division_sub_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled>{{ __('Select Sub Category') }}</option>
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_division_name" class="form-label">{{ __('Division Name') }}</label>
                        <input class="form-control" type="text" id="edit_division_name" name="name" required>
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

{{-- Import Division Modal --}}
<div id="importDivisionModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="importDivisionModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="importDivisionModalLabel">
                    <i class="ri-file-excel-2-line text-success me-1"></i> {{ __('Import Divisions via Excel / CSV') }}
                </h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="importDivisionForm" method="POST" action="{{ route('importDivisions') }}" onsubmit="return false;" enctype="multipart/form-data">
                <div class="modal-body">
                    <div class="alert alert-info border-0 mb-3" role="alert">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <span class="fw-semibold"><i class="ri-information-line me-1"></i>{{ __('Instructions') }}</span>
                            <a href="{{ route('downloadImportSample', ['type' => 'divisions']) }}" class="btn btn-xs btn-primary text-white">
                                <i class="ri-download-2-line me-1"></i>{{ __('Download Sample') }}
                            </a>
                        </div>
                        <small class="text-muted d-block">
                            {{ __('Supported formats: .xlsx, .xls, .csv. Columns required:') }} <strong>Category Name, Sub Category Name, Division Name</strong>.
                        </small>
                    </div>

                    <div class="mb-3">
                        <label for="division_excel_file" class="form-label fw-bold">{{ __('Select File') }} <span class="text-danger">*</span></label>
                        <input type="file" id="division_excel_file" name="file" class="form-control" accept=".xlsx,.xls,.csv" required>
                        <div class="form-text text-muted">{{ __('Maximum file size: 10MB') }}</div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="button" id="btnSubmitImportDivision" class="btn btn-success">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        <i class="ri-upload-cloud-2-line me-1"></i>{{ __('Upload & Import') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
