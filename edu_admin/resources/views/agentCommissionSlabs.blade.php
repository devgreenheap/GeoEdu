@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/agentCommissionSlabs.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="m-0 header-title">{{ __('Agent Commission Slabs') }}</h4>
        <a data-bs-toggle="modal" data-bs-target="#addAgentCommissionSlabModal" class="btn btn-dark ms-auto">{{ __('Add Slab') }}</a>
    </div>
    <div class="card-body">
        <div class="table-responsive">
            <table id="agentCommissionSlabsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Start Level') }}</th>
                        <th>{{ __('End Level') }}</th>
                        <th>{{ __('Commission %') }}</th>
                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

<div id="addAgentCommissionSlabModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add Slab') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addAgentCommissionSlabForm" method="POST">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="start_level" class="form-label">{{ __('Start Level') }}</label>
                        <input class="form-control" type="number" min="1" id="start_level" name="start_level" required>
                    </div>
                    <div class="mb-2">
                        <label for="end_level" class="form-label">{{ __('End Level') }}</label>
                        <input class="form-control" type="number" min="1" id="end_level" name="end_level" required>
                    </div>
                    <div class="mb-2">
                        <label for="commission_percent" class="form-label">{{ __('Commission %') }}</label>
                        <input class="form-control" type="number" min="0" max="99.99" step="0.01" id="commission_percent" name="commission_percent" required>
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

<div id="editAgentCommissionSlabModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit Slab') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editAgentCommissionSlabForm" method="POST">
                <input type="hidden" id="editAgentCommissionSlabId" name="id">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="edit_start_level" class="form-label">{{ __('Start Level') }}</label>
                        <input class="form-control" type="number" min="1" id="edit_start_level" name="start_level" required>
                    </div>
                    <div class="mb-2">
                        <label for="edit_end_level" class="form-label">{{ __('End Level') }}</label>
                        <input class="form-control" type="number" min="1" id="edit_end_level" name="end_level" required>
                    </div>
                    <div class="mb-2">
                        <label for="edit_commission_percent" class="form-label">{{ __('Commission %') }}</label>
                        <input class="form-control" type="number" min="0" max="99.99" step="0.01" id="edit_commission_percent" name="commission_percent" required>
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

