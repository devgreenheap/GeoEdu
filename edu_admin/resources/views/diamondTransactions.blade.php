@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/diamondTransactions.js') }}"></script>
@endsection
@section('content')

<div class="mb-2"></div>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Diamond Transactions') }}
        </h4>
    </div>
    <div class="card-body">
        <div class="table-responsive mt-2">
            <table id="diamondTransactionsTable" class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('User') }}</th>
                        <th>{{ __('Payment Id') }}</th>
                        <th>{{ __('Order Id') }}</th>
                        <th>{{ __('Package') }}</th>
                        <th>{{ __('Diamonds') }}</th>
                        <th>{{ __('Amount') }}</th>
                        <th>{{ __('Status') }}</th>
                        <th>{{ __('Created Date') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
