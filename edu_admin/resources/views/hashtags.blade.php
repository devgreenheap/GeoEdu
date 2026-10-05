@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/hashtags.js') }}"></script>
@endsection
@section('content')

<div class="mb-2">
</div>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Hashtags')}}
        </h4>
        <div class="ms-auto d-flex align-items-center gap-2">
            <button type="button" data-bs-toggle="modal" data-bs-target="#importHashtagModal" class="btn btn-outline-success">
                <i class="ri-file-excel-2-line me-1"></i>{{ __('Import Excel') }}
            </button>
            <a data-bs-toggle="modal" data-bs-target="#addHashtagModal" class="btn btn-dark">{{ __('Add Hashtag')}}</a>
        </div>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table id="hashtagsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3" >
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Hashtag')}}</th>
                        <th>{{ __('Post Count')}}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action')}}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

{{-- Add Modal --}}
<div id="addHashtagModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Hashtag')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addHashtagForm" method="POST">
                <div class="modal-body">

                    <div class="mb-3">
                        <label for="hashtag" class="form-label">{{ __('Hashtag')}}</label>
                        <div class="input-group flex-nowrap">
                            <span class="input-group-text" id="basic-addon1">#</span>
                            <input type="text" id="hashtag" name="hashtag" class="form-control" placeholder="Hashtag" aria-label="Hashtag" aria-describedby="basic-addon1"  pattern="[^@#]*"  required>
                        </div>
                        <span class="fs-6">* Do not include (#,@) symbol</span>
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

{{-- Import Hashtag Modal --}}
<div id="importHashtagModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="importHashtagModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="importHashtagModalLabel">
                    <i class="ri-file-excel-2-line text-success me-1"></i> {{ __('Import Hashtags via Excel / CSV') }}
                </h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="importHashtagForm" method="POST" enctype="multipart/form-data">
                <div class="modal-body">
                    <div class="alert alert-info border-0 mb-3" role="alert">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <span class="fw-semibold"><i class="ri-information-line me-1"></i>{{ __('Instructions') }}</span>
                            <a href="{{ route('downloadImportSample', ['type' => 'hashtags']) }}" class="btn btn-xs btn-primary text-white">
                                <i class="ri-download-2-line me-1"></i>{{ __('Download Sample') }}
                            </a>
                        </div>
                        <small class="text-muted d-block">
                            {{ __('Supported formats: .xlsx, .xls, .csv. Column required:') }} <strong>Hashtag</strong>. {{ __('Prefix (# or @) will be automatically removed.') }}
                        </small>
                    </div>

                    <div class="mb-3">
                        <label for="hashtag_excel_file" class="form-label fw-bold">{{ __('Select File') }} <span class="text-danger">*</span></label>
                        <input type="file" id="hashtag_excel_file" name="file" class="form-control" accept=".xlsx,.xls,.csv" required>
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
