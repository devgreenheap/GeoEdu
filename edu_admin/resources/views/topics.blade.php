@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/topics.js') }}?v={{ @filemtime(public_path('assets/script/topics.js')) }}"></script>
@endsection
@section('content')

<div class="mb-2"></div>

<div class="card">
    <div class="card-body">
        <div class="d-flex align-items-center border-bottom pb-2">
            <h4 class="card-title mb-0 header-title">{{ __('Topics') }}</h4>
            <div class="ms-auto d-flex align-items-center gap-2">
                <button type="button" data-bs-toggle="modal" data-bs-target="#importTopicModal" class="btn btn-outline-success">
                    <i class="ri-file-excel-2-line me-1"></i>{{ __('Import Excel') }}
                </button>
                <a data-bs-toggle="modal" data-bs-target="#addTopicModal" class="btn btn-dark">{{ __('Add') }}</a>
            </div>
        </div>
        <div class="table-responsive mt-2">
            <table id="topicsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Category') }}</th>
                        <th>{{ __('Sub Category') }}</th>
                        <th>{{ __('Division') }}</th>
                        <th>{{ __('Topic') }}</th>
                        <th>{{ __('Created At') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="addTopicModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Topic') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addTopicForm" method="POST">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="topic_category_id" class="form-label">{{ __('Category') }}</label>
                        <select name="category_id" id="topic_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled value="">{{ __('Select Category') }}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="topic_sub_category_id" class="form-label">{{ __('Sub Category') }}</label>
                        <select name="sub_category_id" id="topic_sub_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled value="">{{ __('Select Sub Category') }}</option>
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="topic_division_id" class="form-label">{{ __('Division') }}</label>
                        <select name="division_id" id="topic_division_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                            <option selected value="">{{ __('Select Division (Optional)') }}</option>
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="topic_name" class="form-label">{{ __('Topic') }}</label>
                        <input class="form-control" type="text" id="topic_name" name="name" required>
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

<div id="editTopicModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Topic') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editTopicForm" method="POST">
                <input type="hidden" name="id" id="editTopicId">
                <div class="modal-body">
                    <div class="my-2">
                        <label for="edit_topic_category_id" class="form-label">{{ __('Category') }}</label>
                        <select name="category_id" id="edit_topic_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled value="">{{ __('Select Category') }}</option>
                            @foreach($categories as $category)
                            <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_topic_sub_category_id" class="form-label">{{ __('Sub Category') }}</label>
                        <select name="sub_category_id" id="edit_topic_sub_category_id" class="form-control select2 remove-searchbar" data-toggle="select2" required>
                            <option selected disabled value="">{{ __('Select Sub Category') }}</option>
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_topic_division_id" class="form-label">{{ __('Division') }}</label>
                        <select name="division_id" id="edit_topic_division_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                            <option selected value="">{{ __('Select Division (Optional)') }}</option>
                        </select>
                    </div>
                    <div class="my-2">
                        <label for="edit_topic_name" class="form-label">{{ __('Topic') }}</label>
                        <input class="form-control" type="text" id="edit_topic_name" name="name" required>
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

{{-- Import Topic Modal --}}
<div id="importTopicModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="importTopicModalLabel" aria-hidden="true">
    <div class="modal-dialog modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="importTopicModalLabel">
                    <i class="ri-file-excel-2-line text-success me-1"></i> {{ __('Import Topics via Excel / CSV') }}
                </h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="importTopicForm" method="POST" action="{{ route('importTopics') }}" onsubmit="return false;" enctype="multipart/form-data">
                <div class="modal-body">
                    <div class="alert alert-info border-0 mb-3" role="alert">
                        <div class="d-flex align-items-center justify-content-between mb-1">
                            <span class="fw-semibold"><i class="ri-information-line me-1"></i>{{ __('Instructions') }}</span>
                            <a href="{{ route('downloadImportSample', ['type' => 'topics']) }}" class="btn btn-xs btn-primary text-white">
                                <i class="ri-download-2-line me-1"></i>{{ __('Download Sample') }}
                            </a>
                        </div>
                        <small class="text-muted d-block">
                            {{ __('Supported formats: .xlsx, .xls, .csv. Columns:') }} <strong>Category Name, Sub Category Name, Division Name (Optional), Topic Name</strong>.
                        </small>
                    </div>

                    <div class="mb-3">
                        <label for="topic_excel_file" class="form-label fw-bold">{{ __('Select File') }} <span class="text-danger">*</span></label>
                        <input type="file" id="topic_excel_file" name="file" class="form-control" accept=".xlsx,.xls,.csv" required>
                        <div class="form-text text-muted">{{ __('Maximum file size: 10MB') }}</div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="button" id="btnSubmitImportTopic" class="btn btn-success">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        <i class="ri-upload-cloud-2-line me-1"></i>{{ __('Upload & Import') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
