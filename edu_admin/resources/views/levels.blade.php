@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/levels.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="m-0 header-title">{{ __('Levels') }}</h4>
        <a data-bs-toggle="modal" data-bs-target="#addLevelModal" class="btn btn-dark ms-auto">{{ __('Add Level') }}</a>
    </div>
    <div class="card-body">
        <div class="row g-2 mb-2 align-items-end">
            <div class="col-12 col-md-4">
                <label for="filter_level_only" class="form-label">{{ __('Level') }}</label>
                <input type="text" id="filter_level_only" class="form-control" placeholder="{{ __('Filter by level') }}">
            </div>
            <div class="col-12 col-md-auto d-flex gap-2">
                <button type="button" id="applyLevelFilter" class="btn btn-primary">{{ __('Apply Filters') }}</button>
                <button type="button" id="resetLevelFilter" class="btn btn-light">{{ __('Reset') }}</button>
            </div>
        </div>
        <div class="table-responsive smallSearchBar">
            <table id="levelsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Level') }}</th>
                        <th>{{ __('No. of Comments on Live') }}</th>
                        <th>{{ __('No.of followers') }}</th>
                        <th>{{ __('No. of Send Gifts') }}</th>
                        <th>{{ __('XP Needed To Next Level') }}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="editLevelModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit Level') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editLevelForm" method="POST">
                <input type="hidden" name="id" id="editLevelId">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="edit_level" class="form-label">{{ __('Level') }}</label>
                        <input class="form-control" type="text" id="edit_level" name="level" required disabled>
                    </div>
                    <div class="mb-2">
                        <label for="edit_live_comments_count" class="form-label">{{ __('No. of Comments on Live') }}</label>
                        <input class="form-control" type="number" min="0" id="edit_live_comments_count" name="live_comments_count" required>
                    </div>
                    <div class="mb-2">
                        <label for="edit_host_followers_count" class="form-label">{{ __('No.of followers') }}</label>
                        <input class="form-control" type="number" min="0" id="edit_host_followers_count" name="host_followers_count" required>
                    </div>
                    <div class="mb-2">
                        <label for="edit_send_gifts_count" class="form-label">{{ __('No. of Send Gifts') }}</label>
                        <input class="form-control" type="number" min="0" id="edit_send_gifts_count" name="send_gifts_count" required>
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

<div id="addLevelModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add Level') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addLevelForm" method="POST">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="level" class="form-label">{{ __('Level') }}</label>
                        <input class="form-control" type="text" id="level" name="level" required>
                    </div>
                    <div class="mb-2">
                        <label for="live_comments_count" class="form-label">{{ __('No. of Comments on Live') }}</label>
                        <input class="form-control" type="number" min="0" id="live_comments_count" name="live_comments_count" required>
                    </div>
                    <div class="mb-2">
                        <label for="host_followers_count" class="form-label">{{ __('No.of followers') }}</label>
                        <input class="form-control" type="number" min="0" id="host_followers_count" name="host_followers_count" required>
                    </div>
                    <div class="mb-2">
                        <label for="send_gifts_count" class="form-label">{{ __('No. of Send Gifts') }}</label>
                        <input class="form-control" type="number" min="0" id="send_gifts_count" name="send_gifts_count" required>
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
