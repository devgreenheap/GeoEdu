@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/levelBadges.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="m-0 header-title">{{ __('Level Badges') }}</h4>
        <a data-bs-toggle="modal" data-bs-target="#addLevelBadgeModal" class="btn btn-dark ms-auto">{{ __('Add Level Badge') }}</a>
    </div>
    <div class="card-body">
        <div class="table-responsive smallSearchBar">
            <table id="levelBadgesTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Icon') }}</th>
                        <th>{{ __('Badge Title') }}</th>
                        <th>{{ __('Start Level') }}</th>
                        <th>{{ __('End Level') }}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="editLevelBadgeModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit Level Badge') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editLevelBadgeForm" method="POST">
                <input type="hidden" name="id" id="editLevelBadgeId">
                <div class="modal-body">
                    <img id="imgEditLevelBadgePreview" src="{{ url('assets/img/placeholder.png')}}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="edit_image" class="form-label">{{ __('Icon') }} ({{ __('Select To Edit Only') }})</label>
                        <input class="form-control" type="file" accept="image/*" id="edit_image" name="image">
                    </div>
                    <div class="mb-2">
                        <label for="edit_title" class="form-label">{{ __('Badge Title') }}</label>
                        <input class="form-control" type="text" id="edit_title" name="title" required>
                    </div>
                    <div class="mb-2">
                        <label for="edit_start_level" class="form-label">{{ __('Start Level') }}</label>
                        <input class="form-control" type="number" min="1" id="edit_start_level" name="start_level" required>
                    </div>
                    <div class="mb-2">
                        <label for="edit_end_level" class="form-label">{{ __('End Level') }}</label>
                        <input class="form-control" type="number" min="1" id="edit_end_level" name="end_level" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Submit') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="addLevelBadgeModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add Level Badge') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addLevelBadgeForm" method="POST">
                <div class="modal-body">
                    <img id="imgAddLevelBadgePreview" src="{{ url('assets/img/placeholder.png')}}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="image" class="form-label">{{ __('Icon') }}</label>
                        <input class="form-control" type="file" accept="image/*" id="image" name="image" required>
                    </div>
                    <div class="mb-2">
                        <label for="title" class="form-label">{{ __('Badge Title') }}</label>
                        <input class="form-control" type="text" id="title" name="title" required>
                    </div>
                    <div class="mb-2">
                        <label for="start_level" class="form-label">{{ __('Start Level') }}</label>
                        <input class="form-control" type="number" min="1" id="start_level" name="start_level" required>
                    </div>
                    <div class="mb-2">
                        <label for="end_level" class="form-label">{{ __('End Level') }}</label>
                        <input class="form-control" type="number" min="1" id="end_level" name="end_level" required>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Submit') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
