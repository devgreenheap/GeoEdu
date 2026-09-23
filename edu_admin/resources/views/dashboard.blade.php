@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/dashboard.js') }}"></script>
 {{-- <script src="assets/js/pages/demo.apex-area.js"></script> --}}
@endsection
@section('content')
@php
use App\Models\GlobalFunction;
@endphp

<div class="col-12">
    <div class="card">
        <div class="card-header border-bottom d-flex align-items-center">
            <h4 class="header-title me-auto">{{__('Analytics')}}</h4>
            <select class="picker me-1" name="month" id="months">
                <option value="01">January</option>
                <option value="02">February</option>
                <option value="03">March</option>
                <option value="04">April</option>
                <option value="05">May</option>
                <option value="06">June</option>
                <option value="07">July</option>
                <option value="08">August</option>
                <option value="09">September</option>
                <option value="10">October</option>
                <option value="11">November</option>
                <option value="12">December</option>
            </select>
            <select class="picker" name="year" id="years">
                <option value="2024">2024</option>
                <option value="2025">2025</option>
                <option value="2026">2026</option>
                <option value="2027">2027</option>
            </select>
        </div>
        <div class="card-body">

            <div dir="ltr">
                <div id="chart-dashboard" class="apex-charts" data-colors="#79bb42,#0acf97"></div>
            </div>
        </div>
        <!-- end card body-->
    </div>
    <!-- end card -->
</div>

<div class="row">
    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil uil-users-alt float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0 d-flex align-items-center">
                    {{ __('Total Users') }}
                    <a href="{{route('users')}}" class="d-flex align-items-center justify-content-center fs-4 ms-1 bg-primary-lighten badge text-primary rounded-circle w-h-30">
                        <i class="uil-link-h"></i>
                    </a>
                </h5>
                <h2 class="my-2">{{ GlobalFunction::formatNumber($userTotal) }}</h2>
                <span class="text-muted badge border">
                    <span class="text-danger fw-medium me-1 fs-6">{{ GlobalFunction::formatNumber($userFreezed) }}</span>
                    <span class="text-nowrap fw-medium fs-6">{{ __('Freezed') }}</span>
                </span>
                <span class="text-muted badge border">
                    <span class="text-success fw-medium me-1 fs-6">{{ GlobalFunction::formatNumber($userModerator) }}</span>
                    <span class="text-nowrap fw-medium fs-6">{{ __('Moderators') }}</span>
                </span>
                <span class="text-muted badge border">
                    <span class="text-success fw-medium me-1 fs-6">{{ GlobalFunction::formatNumber($userDummy) }}</span>
                    <span class="text-nowrap fw-medium fs-6">{{ __('Dummy') }}</span>
                </span>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil-users-alt float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0 d-flex align-items-center">
                    {{ __('Total Hosts') }}
                    <a href="{{route('users')}}" class="d-flex align-items-center justify-content-center fs-4 ms-1 bg-primary-lighten badge text-primary rounded-circle w-h-30">
                        <i class="uil-link-h"></i>
                    </a>
                </h5>
                <h2 class="my-2">{{ GlobalFunction::formatNumber($totalHosts) }}</h2>
                <span class="text-muted fs-6">{{ __('Users eligible for live hosting') }}</span>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil-bolt float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0 d-flex align-items-center">
                    {{ __('Live Users (Real-time)') }}
                </h5>
                <h2 class="my-2">{{ GlobalFunction::formatNumber($liveUsersRealtime) }}</h2>
                <span class="text-muted fs-6">{{ __('Active in last') }} {{ $liveWindowMinutes }} {{ __('minutes') }}</span>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil-video float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0 d-flex align-items-center">
                    {{ __('Ongoing Live Sessions') }}
                </h5>
                <h2 class="my-2">{{ GlobalFunction::formatNumber($ongoingLiveSessions) }}</h2>
                <span class="text-muted fs-6">{{ __('Estimated active hosts') }}</span>
            </div>
        </div>
    </div>
</div>

<div class="row">
    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil-diamond float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0">{{ __('Total Diamonds Purchased') }}</h5>
                <h2 class="my-2">{{ GlobalFunction::formatNumber($totalDiamondsPurchased) }}</h2>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil-star float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0">{{ __('Total Stars Earned') }}</h5>
                <h2 class="my-2">{{ GlobalFunction::formatNumber($totalStarsEarned) }}</h2>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil-dollar-alt float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0">{{ __('Total Revenue') }}</h5>
                <h2 class="my-2">{{ $currency }} {{ number_format($totalRevenue, 2) }}</h2>
                <span class="text-muted fs-6">{{ __('Based on purchased diamonds x star value') }}</span>
            </div>
        </div>
    </div>

    <div class="col-md-3">
        <div class="card">
            <div class="card-body">
                <div class="tilebox-one">
                    <i class='uil-chart-line float-end'></i>
                </div>
                <h5 class="text-uppercase mt-0">{{ __('Today / Weekly / Monthly Growth Stats') }}</h5>
                <div id="growth-stats-chart"
                    data-today="{{ $todayNewUsers }}"
                    data-weekly="{{ $weeklyNewUsers }}"
                    data-monthly="{{ $monthlyNewUsers }}"
                    data-today-growth="{{ $todayGrowthPercent }}"
                    data-weekly-growth="{{ $weeklyGrowthPercent }}"
                    data-monthly-growth="{{ $monthlyGrowthPercent }}"></div>
            </div>
        </div>
    </div>
</div>


@endsection
