@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/agentCommissionTransactions.js') }}"></script>
@endsection
@section('content')

<div class="mb-2"></div>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Agent Commission Transactions') }}
        </h4>
    </div>
    <div class="card-body">
        <div class="table-responsive mt-2">
            <table id="agentCommissionTransactionsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('ID') }}</th>
                        <th>{{ __('Agent') }}</th>
                        <th>{{ __('Buyer User') }}</th>
                        <th>{{ __('Amount') }}</th>
                        <th>{{ __('Commission %') }}</th>
                        <th>{{ __('Commission Amount') }}</th>
                        <th>{{ __('Created Date') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
