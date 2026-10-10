@extends('include.app')
@section('script')
    <script src="{{ asset('assets/script/settings.js') }}"></script>
    <!-- Quill Editor js -->
    <script src="{{ asset('assets/vendor/quill/quill.js') }}"></script>
    <script>
        // Add new SHA field
        $("#addSha").on("click", function() {
            let field = `
            <div class="input-group mb-2 sha-field">
                <input type="text" class="form-control sha-input" name="sha_256[]" placeholder="Enter SHA 256">
                <button type="button" class="btn btn-danger remove-sha">-</button>
            </div>`;
            $("#shaContainer").append(field);
        });

        // Remove SHA field
        $(document).on("click", ".remove-sha", function() {
            $(this).closest(".sha-field").remove();
        });

        $(document).ready(function() {
            $("#checkValidationOfApple").on("click", function() {
                let baseUrl = "https://app-site-association.cdn-apple.com/a/v1/baseUrl";

                let appUrl = "{{ config('app.url') }}";
                // Remove trailing slash
                let domainOnly = appUrl.replace(/^https?:\/\//, '').replace(/\/$/, '');

                let newUrl = baseUrl.replace("baseUrl", domainOnly);

                window.open(newUrl, "_blank");
            });

            $("#checkValidationOfAndroid").on("click", function() {
                let baseUrl =
                    "https://digitalassetlinks.googleapis.com/v1/statements:list?source.web.site=baseUrl&relation=delegate_permission/common.handle_all_urls";

                let appUrl = "{{ config('app.url') }}";
                // Remove trailing slash
                let cleanUrl = appUrl.replace(/\/$/, '');

                let newUrl = baseUrl.replace("baseUrl", cleanUrl);

                window.open(newUrl, "_blank");
            });
        });
    </script>
@endsection

@section('content')
    <div class="row">
        <div class="col-sm-2 mb-2 mb-sm-0">
            <div class="card">
                <div class="card-body p-2">
                    <div class="nav flex-column nav-pills" id="v-pills-tab" role="tablist" aria-orientation="vertical">
                        <a class="main-nav-link nav-link first-nav-link" id="v-pills-appSettings-tab" data-bs-toggle="pill"
                            href="#v-pills-appSettings" role="tab" aria-controls="v-pills-password"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('App Settings') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-invoiceSettings-tab" data-bs-toggle="pill"
                            href="#v-pills-invoiceSettings" role="tab" aria-controls="v-pills-invoiceSettings"
                            aria-selected="false">
                            <i class="mdi mdi-receipt-text-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Invoice Settings') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-limits-tab" data-bs-toggle="pill"
                            href="#v-pills-limits" role="tab" aria-controls="v-pills-limits" aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Limits') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-livestream-tab" data-bs-toggle="pill"
                            href="#v-pills-livestream" role="tab" aria-controls="v-pills-livestream"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Livestream') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-gif-tab" data-bs-toggle="pill" href="#v-pills-gif"
                            role="tab" aria-controls="v-pills-gif" aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('GIPHY') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-sightEngine-tab" data-bs-toggle="pill"
                            href="#v-pills-sightEngine" role="tab" aria-controls="v-pills-sightEngine"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('SightEngine') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-onBoarding-tab" data-bs-toggle="pill"
                            href="#v-pills-onBoarding" role="tab" aria-controls="v-pills-onBoarding"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Onboarding') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-reportReasons-tab" data-bs-toggle="pill"
                            href="#v-pills-reportReasons" role="tab" aria-controls="v-pills-reportReasons"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Report Reasons') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-withdrawalGateways-tab" data-bs-toggle="pill"
                            href="#v-pills-withdrawalGateways" role="tab" aria-controls="v-pills-withdrawalGateways"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Withdrawal Gateways') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-deepar-tab" data-bs-toggle="pill"
                            href="#v-pills-deepar" role="tab" aria-controls="v-pills-deepar" aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('DeepAR Settings') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-deeplinking-tab" data-bs-toggle="pill"
                            href="#v-pills-deeplinking" role="tab" aria-controls="v-pills-deeplinking"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Deeplink Settings') }}</span>
                        </a>
                        <hr>
                        <a class="main-nav-link nav-link" id="v-pills-privacy-policy-tab" data-bs-toggle="pill"
                            href="#v-pills-privacy-policy" role="tab" aria-controls="v-pills-privacy-policy"
                            aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Privacy Policy') }}</span>
                        </a>
                        <a class="main-nav-link nav-link" id="v-pills-terms-tab" data-bs-toggle="pill"
                            href="#v-pills-terms" role="tab" aria-controls="v-pills-terms" aria-selected="false">
                            <i class="mdi mdi-settings-outline d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Terms Of Uses') }}</span>
                        </a>
                        <hr>
                        <a class="main-nav-link nav-link " id="v-pills-setting-tab" data-bs-toggle="pill"
                            href="#v-pills-setting" role="tab" aria-controls="v-pills-setting" aria-selected="true">
                            <i class="mdi mdi-home-variant d-md-none d-block"></i>
                            <span class="d-none d-md-block">{{ __('Admin Settings') }}</span>
                        </a>
                    </div>
                </div>
            </div>
        </div>
        <div class="col-sm-10">
            <div class="tab-content" id="v-pills-tabContent">
                {{-- Admin Settings --}}
                <div class="tab-pane fade " id="v-pills-setting" role="tabpanel" aria-labelledby="v-pills-setting-tab">
                    {{-- 1st card --}}
                    <div class="card">
                        <div class="card-header border-bottom">
                            <h4 class="m-0 header-title">{{ __('Admin Settings') }}</h4>
                        </div>
                        <div class="card-body">
                            <form id="brandSettingForm" method="POST">
                                <div class="row">
                                    <div class="col-md-3 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="title" class="form-label">{{ __('Title') }}</label>
                                            <input type="text" class="form-control" id="app_name" name="app_name"
                                                placeholder="Enter title" value="{{ $setting->app_name }}">
                                        </div>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="favicon" class="form-label">{{ __('Favicon') }}</label>
                                            <input type="file" id="favicon" name="favicon" class="form-control">
                                            <img class="mt-2" width="80"
                                                src="{{ asset('assets/img/favicon.png') }}" alt="">
                                        </div>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="logo_dark" class="form-label">{{ __('Logo (Dark)') }}</label>
                                            <input type="file" id="logo_dark" name="logo_dark" class="form-control">
                                            <img class="mt-2" width="80"
                                                src="{{ asset('assets/img/logo-dark.png') }}" alt="">
                                        </div>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="logo_light" class="form-label">{{ __('Logo (Light)') }}</label>
                                            <input type="file" id="logo_light" name="logo_light"
                                                class="form-control">
                                            <img class="mt-2" width="80" src="{{ asset('assets/img/logo.png') }}"
                                                alt="">
                                        </div>
                                    </div>
                                </div>
                                <hr>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                    {{-- Password --}}
                    @if ($userType == 1)
                        <div class="card">
                            <div class="card-header border-bottom">
                                <h4 class="m-0 header-title">{{ __('Password') }}</h4>
                            </div>
                            <div class="card-body">
                                <form id="changePasswordForm" method="POST">
                                    <input type="hidden" name="user_type" value="{{ $userType }}">
                                    <div class="row mb-3">
                                        <div class="col-md-3 mb-3">
                                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                                <label for="password" class="form-label">{{ __('Old Password') }}</label>
                                                <div class="input-group input-group-merge">
                                                    <input type="password" id="password" name="old_password"
                                                        class="form-control" placeholder="Enter your password">
                                                    <div class="input-group-text" data-password="false">
                                                        <span class="password-eye"></span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                        <div class="col-md-3 mb-3">
                                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                                <label for="password" class="form-label">{{ __('New Password') }}</label>
                                                <div class="input-group input-group-merge">
                                                    <input type="password" id="new_password" name="new_password"
                                                        class="form-control" placeholder="Enter your password">
                                                    <div class="input-group-text" data-password="false">
                                                        <span class="password-eye"></span>
                                                    </div>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                    <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                                </form>
                            </div>
                        </div>
                    @endif

                </div>
                {{-- App Settings --}}
                <div class="tab-pane fade first-tab-pane" id="v-pills-appSettings" role="tabpanel"
                    aria-labelledby="v-pills-password-tab">
                    {{-- 1st card --}}
                    <div class="card">
                        <div class="card-header border-bottom">
                            <h4 class="m-0 header-title">{{ __('App Settings') }}</h4>
                        </div>
                        <div class="card-body">
                            <span class="fs-6">*Make sure to set star value according to your currency.</span><br>
                            <span class="fs-6">*Users can use withdrawal functions only if it the switch is on
                                below.</span>
                            <form class="mt-2" id="basicSettingForm" method="POST">
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="currency" class="form-label">{{ __('Currency') }}</label>
                                            <input type="text" class="form-control" id="currency" name="currency"
                                                value="{{ $setting->currency }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="coin_value" class="form-label">1 {{ __('Star Value') }}</label>
                                            <input type="number" step="any" class="form-control" id="coin_value"
                                                name="coin_value" value="{{ $setting->coin_value }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="diamond_to_star_rate" class="form-label">{{ __('1 Diamond = Stars') }}</label>
                                            <input type="number" step="any" min="0.01" class="form-control" id="diamond_to_star_rate"
                                                name="diamond_to_star_rate" value="{{ $setting->diamond_to_star_rate ?? 1 }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="host_commission" class="form-label">{{ __('Host Commission (%)') }}</label>
                                            <input type="number" step="any" min="0" class="form-control" id="host_commission"
                                                name="host_commission" value="{{ $setting->host_commission ?? 0 }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="admin_commision" class="form-label">{{ __('Admin Commision (%)') }}</label>
                                            <input type="number" step="any" min="0" class="form-control" id="admin_commision"
                                                name="admin_commision" value="{{ $setting->admin_commision ?? 0 }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="agent_commision" class="form-label">{{ __('Agent Commision (%)') }}</label>
                                            <input type="number" step="any" min="0" class="form-control" id="agent_commision"
                                                name="agent_commision" value="{{ $setting->agent_commision ?? 0 }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="state_agent_commision" class="form-label">{{ __('State Agent Commision (%)') }}</label>
                                            <input type="number" step="any" min="0" class="form-control" id="state_agent_commision"
                                                name="state_agent_commision" value="{{ $setting->state_agent_commision ?? 0 }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="gifter_return" class="form-label">{{ __('Gifter Return (%)') }}</label>
                                            <input type="number" step="any" min="0" class="form-control" id="gifter_return"
                                                name="gifter_return" value="{{ $setting->gifter_return ?? 0 }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="min_redeem_coins"
                                                class="form-label">{{ __('Min. Stars To Withdraw') }}</label>
                                            <input type="number" min="1" step="1" class="form-control"
                                                id="min_redeem_coins" name="min_redeem_coins"
                                                value="{{ $setting->min_redeem_coins }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="help_mail" class="form-label">{{ __('Help Email') }}</label>
                                            <input type="email" class="form-control" id="help_mail" name="help_mail"
                                                value="{{ $setting->help_mail }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for=""
                                                class="form-label">{{ __('Compress Post/Story Videos') }}</label>
                                            <div class="mb-0">
                                                <input name="is_compress" type="checkbox" id="switchCompressVideosStatus"
                                                    {{ $setting->is_compress == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchCompressVideosStatus"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for=""
                                                class="form-label">{{ __('Allow Withdrawal Of Stars') }}</label>
                                            <div class="mb-0">
                                                <input name="is_withdrawal_on" type="checkbox" id="switchWithdrawal"
                                                    {{ $setting->is_withdrawal_on == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchWithdrawal"></label>
                                            </div>
                                        </div>
                                    </div>
                                </div>
                                {{-- Watermark --}}
                                <h5>{{ __('REWARD SETTINGS') }}</h5>
                                <hr>
                                <span class="fs-6">*Users will get the following number of diamonds as a bonus when they
                                    register, if the switch below is turned on.</span><br>
                                <div class="row mt-2">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for=""
                                                class="form-label">{{ __('Registration Bonus Status') }}</label>
                                            <div class="mb-0">
                                                <input name="registration_bonus_status" type="checkbox"
                                                    id="switcRegistrationBonusStatus"
                                                    {{ $setting->registration_bonus_status == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switcRegistrationBonusStatus"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="registration_bonus_amount"
                                                class="form-label">{{ __('Registration Bonus Amount (Diamonds)') }}</label>
                                            <input type="number" min="1" step="1" class="form-control"
                                                id="registration_bonus_amount" name="registration_bonus_amount"
                                                value="{{ $setting->registration_bonus_amount }}">
                                        </div>
                                    </div>
                                </div>
                                {{-- Watermark --}}
                                <h5>{{ __('WATERMARK SETTINGS') }}</h5>
                                <hr>
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="" class="form-label">{{ __('Watermark Videos') }}</label>
                                            <div class="mb-0">
                                                <input name="watermark_status" type="checkbox" id="switchWatermarkStatus"
                                                    {{ $setting->watermark_status == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchWatermarkStatus"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="watermark_image"
                                                class="form-label">{{ __('Watermark Image') }}</label>
                                            <input type="file" id="watermark_image" name="watermark_image"
                                                class="form-control">
                                            <img class="mt-2" width="80"
                                                src="{{ $baseUrl }}{{ $setting->watermark_image }}" alt="">
                                        </div>
                                    </div>
                                </div>


                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>

                        </div>
                    </div>

                </div>
                {{-- Invoice Settings --}}
                <div class="tab-pane fade" id="v-pills-invoiceSettings" role="tabpanel"
                    aria-labelledby="v-pills-invoiceSettings-tab">
                    <div class="card">
                        <div class="card-header border-bottom d-flex align-items-center justify-content-between">
                            <div>
                                <h4 class="m-0 header-title">{{ __('Invoice Settings') }}</h4>
                                <p class="text-muted font-13 mb-0">{{ __('Control all tax invoice settings, SGST/CGST/IGST toggles, company information, logo, signature, and legal notes.') }}</p>
                            </div>
                            <span class="badge bg-primary-lighten text-primary fs-6"><i class="mdi mdi-receipt me-1"></i>{{ __('Tax Invoice') }}</span>
                        </div>
                        <div class="card-body">
                            <form id="invoiceSettingForm" method="POST" enctype="multipart/form-data">
                                {{-- Section 1: Tax Configuration --}}
                                <div class="d-flex align-items-center mb-2">
                                    <h5 class="text-uppercase text-primary mb-0"><i class="mdi mdi-percent-outline me-1"></i>{{ __('TAX CONFIGURATION (GST / TAXES)') }}</h5>
                                </div>
                                <span class="fs-6 text-muted mb-3 d-block">*{{ __('Enable or disable each tax independently. Disabled taxes will be excluded from calculation and hidden from the user\'s invoice.') }}</span>

                                <div class="row">
                                    {{-- SGST --}}
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3 h-100">
                                            <div class="d-flex justify-content-between align-items-center mb-2">
                                                <label for="switchSgst" class="form-label fw-bold mb-0">{{ __('SGST (State GST)') }}</label>
                                                <input name="invoice_sgst_enabled" type="checkbox" id="switchSgst"
                                                    {{ ($setting->invoice_sgst_enabled ?? 0) == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchSgst" class="mb-0"></label>
                                            </div>
                                            <div class="mt-2">
                                                <label for="invoice_sgst_percent" class="form-label font-13 text-muted">{{ __('SGST Rate (%)') }}</label>
                                                <div class="input-group input-group-sm">
                                                    <input type="number" step="0.01" min="0" max="100" class="form-control"
                                                        id="invoice_sgst_percent" name="invoice_sgst_percent"
                                                        value="{{ $setting->invoice_sgst_percent ?? 0.00 }}">
                                                    <span class="input-group-text">%</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {{-- CGST --}}
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3 h-100">
                                            <div class="d-flex justify-content-between align-items-center mb-2">
                                                <label for="switchCgst" class="form-label fw-bold mb-0">{{ __('CGST (Central GST)') }}</label>
                                                <input name="invoice_cgst_enabled" type="checkbox" id="switchCgst"
                                                    {{ ($setting->invoice_cgst_enabled ?? 0) == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchCgst" class="mb-0"></label>
                                            </div>
                                            <div class="mt-2">
                                                <label for="invoice_cgst_percent" class="form-label font-13 text-muted">{{ __('CGST Rate (%)') }}</label>
                                                <div class="input-group input-group-sm">
                                                    <input type="number" step="0.01" min="0" max="100" class="form-control"
                                                        id="invoice_cgst_percent" name="invoice_cgst_percent"
                                                        value="{{ $setting->invoice_cgst_percent ?? 0.00 }}">
                                                    <span class="input-group-text">%</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {{-- IGST --}}
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3 h-100">
                                            <div class="d-flex justify-content-between align-items-center mb-2">
                                                <label for="switchIgst" class="form-label fw-bold mb-0">{{ __('IGST (Integrated GST)') }}</label>
                                                <input name="invoice_igst_enabled" type="checkbox" id="switchIgst"
                                                    {{ ($setting->invoice_igst_enabled ?? 1) == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchIgst" class="mb-0"></label>
                                            </div>
                                            <div class="mt-2">
                                                <label for="invoice_igst_percent" class="form-label font-13 text-muted">{{ __('IGST Rate (%)') }}</label>
                                                <div class="input-group input-group-sm">
                                                    <input type="number" step="0.01" min="0" max="100" class="form-control"
                                                        id="invoice_igst_percent" name="invoice_igst_percent"
                                                        value="{{ $setting->invoice_igst_percent ?? 18.00 }}">
                                                    <span class="input-group-text">%</span>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {{-- Silver Jewel GST (%) --}}
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3 h-100">
                                            <label for="silver_jewel_gst_percent" class="form-label fw-bold mb-1">{{ __('Silver Jewel GST (%)') }}</label>
                                            <p class="font-12 text-muted mb-2">{{ __('Applied to silver jewel products during package invoice calculation.') }}</p>
                                            <div class="input-group">
                                                <input type="number" step="0.01" min="0" max="100" class="form-control"
                                                    id="silver_jewel_gst_percent" name="silver_jewel_gst_percent"
                                                    value="{{ $setting->silver_jewel_gst_percent ?? '' }}" placeholder="0.00">
                                                <span class="input-group-text">%</span>
                                            </div>
                                        </div>
                                    </div>

                                    {{-- Making Charge Percent (%) --}}
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3 h-100">
                                            <label for="making_charge_percent" class="form-label fw-bold mb-1">{{ __('Making Charge Percent (%)') }}</label>
                                            <p class="font-12 text-muted mb-2">{{ __('Making charge percentage applied during package invoice calculation.') }}</p>
                                            <div class="input-group">
                                                <input type="number" step="0.01" min="0" max="100" class="form-control"
                                                    id="making_charge_percent" name="making_charge_percent"
                                                    value="{{ $setting->making_charge_percent ?? '' }}" placeholder="0.00">
                                                <span class="input-group-text">%</span>
                                            </div>
                                        </div>
                                    </div>

                                    {{-- Handling Fee (₹) --}}
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3 h-100">
                                            <label for="handling_fee" class="form-label fw-bold mb-1">{{ __('Handling Fee (₹)') }}</label>
                                            <p class="font-12 text-muted mb-2">{{ __('Fixed handling fee reflected in the invoice calculation.') }}</p>
                                            <div class="input-group">
                                                <span class="input-group-text">₹</span>
                                                <input type="number" step="0.01" min="0" class="form-control"
                                                    id="handling_fee" name="handling_fee"
                                                    value="{{ $setting->handling_fee ?? '' }}" placeholder="0.00">
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <hr class="my-3">

                                {{-- Section 2: Company Information --}}
                                <h5 class="text-uppercase text-primary mb-2"><i class="mdi mdi-office-building-outline me-1"></i>{{ __('COMPANY INFORMATION (SHOWN ON INVOICE)') }}</h5>

                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_company_name" class="form-label">{{ __('Company / Legal Name') }}</label>
                                            <input type="text" class="form-control" id="invoice_company_name" name="invoice_company_name"
                                                value="{{ $setting->invoice_company_name ?? 'Greenheap DigiEdu Private Limited' }}" required>
                                        </div>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_gstin" class="form-label">{{ __('GSTIN') }}</label>
                                            <input type="text" class="form-control text-uppercase" id="invoice_gstin" name="invoice_gstin"
                                                value="{{ $setting->invoice_gstin ?? '29AAGCG1234F1Z5' }}" required>
                                        </div>
                                    </div>
                                    <div class="col-md-3 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_hsn_code" class="form-label">{{ __('HSN Code') }}</label>
                                            <input type="text" class="form-control" id="invoice_hsn_code" name="invoice_hsn_code"
                                                value="{{ $setting->invoice_hsn_code ?? '998439' }}" placeholder="e.g. 7113 / 998439" required>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_company_email" class="form-label">{{ __('Company Email') }}</label>
                                            <input type="email" class="form-control" id="invoice_company_email" name="invoice_company_email"
                                                value="{{ $setting->invoice_company_email ?? 'support@geoedu.com' }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_phone_number" class="form-label">{{ __('Company Phone') }}</label>
                                            <input type="text" class="form-control" id="invoice_phone_number" name="invoice_phone_number"
                                                value="{{ $setting->invoice_phone_number ?? '+91 9876543210' }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_place_of_supply" class="form-label">{{ __('Default Place of Supply') }}</label>
                                            <input type="text" class="form-control" id="invoice_place_of_supply" name="invoice_place_of_supply"
                                                value="{{ $setting->invoice_place_of_supply ?? 'Tamil Nadu, India' }}">
                                        </div>
                                    </div>
                                    <div class="col-12 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_company_address" class="form-label">{{ __('Company Address') }}</label>
                                            <textarea class="form-control" id="invoice_company_address" name="invoice_company_address" rows="2" required>{{ $setting->invoice_company_address ?? 'No 1090n, Sector 3, 18th Cross Road, Bengaluru Urban, Karnataka, 560102' }}</textarea>
                                        </div>
                                    </div>
                                </div>

                                <hr class="my-3">

                                {{-- Section 3: Company Logo & Authorized Signature --}}
                                <h5 class="text-uppercase text-primary mb-2"><i class="mdi mdi-image-outline me-1"></i>{{ __('COMPANY LOGO & AUTHORIZED SIGNATURE') }}</h5>

                                <div class="row">
                                    {{-- Company Logo --}}
                                    <div class="col-md-6 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3">
                                            <label for="invoice_company_logo" class="form-label fw-bold">{{ __('Company Logo') }}</label>
                                            <input type="file" id="invoice_company_logo" name="invoice_company_logo" class="form-control" accept="image/*">
                                            <div class="mt-2 d-flex align-items-center gap-3">
                                                <div class="border rounded p-1 bg-white" style="width: 90px; height: 90px; display: flex; align-items: center; justify-content: center;">
                                                    <img id="imgCompanyLogoPreview"
                                                        src="{{ !empty($setting->invoice_company_logo) ? $baseUrl . $setting->invoice_company_logo : asset('assets/images/app_logo.png') }}"
                                                        alt="Logo Preview" style="max-width: 100%; max-height: 100%; object-fit: contain;">
                                                </div>
                                                <div>
                                                    <span class="badge bg-info-lighten text-info mb-1">{{ __('Preview') }}</span>
                                                    <p class="text-muted small mb-0">{{ __('Recommended: PNG with transparent background. Appears at the top right of the invoice.') }}</p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>

                                    {{-- Signature Image --}}
                                    <div class="col-md-6 mb-3">
                                        <div class="bg-secondary-lighten border p-3 rounded-3">
                                            <label for="invoice_signature_image" class="form-label fw-bold">{{ __('Authorized Signature Image') }}</label>
                                            <input type="file" id="invoice_signature_image" name="invoice_signature_image" class="form-control" accept="image/*">
                                            <div class="mt-2 d-flex align-items-center gap-3">
                                                <div class="border rounded p-1 bg-white" style="width: 120px; height: 90px; display: flex; align-items: center; justify-content: center;">
                                                    <img id="imgSignaturePreview"
                                                        src="{{ !empty($setting->invoice_signature_image) ? $baseUrl . $setting->invoice_signature_image : '' }}"
                                                        alt="Signature Preview" style="max-width: 100%; max-height: 100%; object-fit: contain; {{ empty($setting->invoice_signature_image) ? 'display: none;' : '' }}">
                                                    <span id="noSignatureText" class="text-muted small text-center" style="{{ !empty($setting->invoice_signature_image) ? 'display: none;' : '' }}">{{ __('No signature uploaded') }}</span>
                                                </div>
                                                <div>
                                                    <span class="badge bg-info-lighten text-info mb-1">{{ __('Preview') }}</span>
                                                    <p class="text-muted small mb-0">{{ __('Recommended: PNG signature on transparent background. Displayed above the Authorised Signatory label.') }}</p>
                                                </div>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <hr class="my-3">

                                {{-- Section 4: Invoice Configuration & Texts --}}
                                <h5 class="text-uppercase text-primary mb-2"><i class="mdi mdi-file-document-edit-outline me-1"></i>{{ __('INVOICE CONFIGURATION & LEGAL TEXTS') }}</h5>

                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_title" class="form-label">{{ __('Invoice Title') }}</label>
                                            <input type="text" class="form-control" id="invoice_title" name="invoice_title"
                                                value="{{ $setting->invoice_title ?? 'Tax Invoice' }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_prefix" class="form-label">{{ __('Invoice Prefix / Format') }}</label>
                                            <input type="text" class="form-control" id="invoice_prefix" name="invoice_prefix"
                                                value="{{ $setting->invoice_prefix ?? 'GEO' }}">
                                            <small class="text-muted font-11">{{ __('e.g. GEO will generate GEO/YYYY-YYYY/MM/ID') }}</small>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_currency" class="form-label">{{ __('Currency Symbol / Label') }}</label>
                                            <input type="text" class="form-control" id="invoice_currency" name="invoice_currency"
                                                value="{{ $setting->invoice_currency ?? 'Rs.' }}">
                                        </div>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_signatory_name" class="form-label">{{ __('Authorized Signatory Text / Name') }}</label>
                                            <input type="text" class="form-control" id="invoice_signatory_name" name="invoice_signatory_name"
                                                value="{{ $setting->invoice_signatory_name ?? 'GeoEdu Auth' }}">
                                        </div>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_terms_text" class="form-label">{{ __('Terms & Conditions Text') }}</label>
                                            <input type="text" class="form-control" id="invoice_terms_text" name="invoice_terms_text"
                                                value="{{ $setting->invoice_terms_text ?? 'Refer to geoedu.com/terms for Policy, Terms & Conditions.' }}">
                                        </div>
                                    </div>
                                    <div class="col-12 mb-3">
                                        <div class="bg-secondary-lighten border p-2 rounded-3">
                                            <label for="invoice_footer_text" class="form-label">{{ __('Footer Notes (Reverse Charge / Inter-state notice)') }}</label>
                                            <textarea class="form-control" id="invoice_footer_text" name="invoice_footer_text" rows="2">{{ $setting->invoice_footer_text ?? "Tax payable on reverse charge - No.\n*In case of inter-state supply IGST will be applicable. Within state supplies are liable for CGST & SGST." }}</textarea>
                                        </div>
                                    </div>
                                </div>

                                <div class="mt-2">
                                    <button type="submit" class="btn btn-primary" id="saveInvoiceSettingsBtn">
                                        <span class="spinner-border spinner-border-sm me-1 hide" role="status" aria-hidden="true"></span>
                                        <i class="mdi mdi-content-save me-1"></i> {{ __('Save Invoice Settings') }}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>

                {{-- Limits --}}
                <div class="tab-pane fade" id="v-pills-limits" role="tabpanel" aria-labelledby="v-pills-limits-tab">
                    <div class="card">
                        <div class="card-header border-bottom">
                            <h4 class="m-0 header-title">{{ __('Limits') }}</h4>
                        </div>
                        <div class="card-body">
                            <form id="limitSettingForm" method="POST">
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_upload_daily"
                                                class="form-label">{{ __('Max. Post Upload/Day') }}</label>
                                            <input type="number" min="1" class="form-control"
                                                id="max_upload_daily" name="max_upload_daily"
                                                value="{{ $setting->max_upload_daily }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_story_daily"
                                                class="form-label">{{ __('Max. Stories/Day') }}</label>
                                            <input type="number" min="1" class="form-control"
                                                id="max_story_daily" name="max_story_daily"
                                                value="{{ $setting->max_story_daily }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_comment_daily"
                                                class="form-label">{{ __('Max. Comments/Day') }}</label>
                                            <input type="number" min="1" class="form-control"
                                                id="max_comment_daily" name="max_comment_daily"
                                                value="{{ $setting->max_comment_daily }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_comment_reply_daily"
                                                class="form-label">{{ __('Max. Comment Reply/Day') }}</label>
                                            <input type="number" min="1" class="form-control"
                                                id="max_comment_reply_daily" name="max_comment_reply_daily"
                                                value="{{ $setting->max_comment_reply_daily }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_post_pins"
                                                class="form-label">{{ __('Max. Post Pins') }}</label>
                                            <input type="number" min="1" class="form-control" id="max_post_pins"
                                                name="max_post_pins" value="{{ $setting->max_post_pins }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_comment_pins"
                                                class="form-label">{{ __('Max. Comment Pins') }}</label>
                                            <input type="number" min="1" class="form-control"
                                                id="max_comment_pins" name="max_comment_pins"
                                                value="{{ $setting->max_comment_pins }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_images_per_post"
                                                class="form-label">{{ __('Max. Images Per Post') }}</label>
                                            <input type="number" min="1" class="form-control"
                                                id="max_images_per_post" name="max_images_per_post"
                                                value="{{ $setting->max_images_per_post }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="max_user_links"
                                                class="form-label">{{ __('Max. User Links') }}</label>
                                            <input type="number" min="1" class="form-control"
                                                id="max_user_links" name="max_user_links"
                                                value="{{ $setting->max_user_links }}">
                                        </div>
                                    </div>
                                </div>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
                {{-- Livestream --}}
                <div class="tab-pane fade" id="v-pills-livestream" role="tabpanel"
                    aria-labelledby="v-pills-livestream-tab">
                    <div class="card">
                        <div class="card-header border-bottom">
                            <h4 class="m-0 header-title">{{ __('Livestream') }}</h4>
                        </div>
                        <div class="card-body">
                            <span class="fs-6">* Set 0 as a value either in Timeout Minutes or Min. Viewers required to
                                stop Livestream Timeout function.</span><br>
                            <span class="fs-6">* If you turn ON dummy live streams, It will display dummy lives on the
                                app. In order to show dummy lives, There must be dummy live videos added in the list.</span>
                            <form class="mt-2" id="livestreamSettingForm" method="POST">
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="min_followers_for_live"
                                                class="form-label">{{ __('Min. Followers needed to go Live') }}</label>
                                            <input type="number" step="1" class="form-control"
                                                id="min_followers_for_live" name="min_followers_for_live"
                                                value="{{ $setting->min_followers_for_live }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="live_min_viewers"
                                                class="form-label">{{ __('Min. Viewers Required to continue live') }}</label>
                                            <input type="number" step="1" class="form-control"
                                                id="live_min_viewers" name="live_min_viewers"
                                                value="{{ $setting->live_min_viewers }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="live_timeout"
                                                class="form-label">{{ __('Time Out Minutes (if not get min. viewers)') }}</label>
                                            <input type="number" step="1" class="form-control" id="live_timeout"
                                                name="live_timeout" value="{{ $setting->live_timeout }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="" class="form-label">{{ __('PK Battle') }}</label>
                                            <div class="mb-0">
                                                <input name="live_battle" type="checkbox" id="switchPKBattle"
                                                    {{ $setting->live_battle == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchPKBattle"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for=""
                                                class="form-label">{{ __('Dummy Live Streams') }}</label>
                                            <div class="mb-0">
                                                <input name="live_dummy_show" type="checkbox" id="switchDummyLiveShow"
                                                    {{ $setting->live_dummy_show == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchDummyLiveShow"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="battle_duration_minutes"
                                                class="form-label">{{ __('Battle Duration (Minutes)') }}</label>
                                            <input type="number" min="1" step="1" class="form-control"
                                                id="battle_duration_minutes" name="battle_duration_minutes"
                                                value="{{ $setting->battle_duration_minutes ?? 1 }}">
                                        </div>
                                    </div>
                                </div>
                                {{-- Watermark --}}
                                <h5>{{ __('ZEGO CLOUD SETTINGS') }}</h5>
                                <hr>
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="zego_app_id"
                                                class="form-label">{{ __('Zego Cloud App ID') }}</label>
                                            <input type="text" class="form-control" id="zego_app_id"
                                                name="zego_app_id"
                                                value="{{ $userType == 0 ? '---------' : $setting->zego_app_id }}">
                                        </div>
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="zego_app_sign"
                                                class="form-label">{{ __('Zego Cloud App Sign') }}</label>
                                            <input type="text" class="form-control" id="zego_app_sign"
                                                name="zego_app_sign"
                                                value="{{ $userType == 0 ? '---------' : $setting->zego_app_sign }}">
                                        </div>
                                    </div>
                                </div>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
                {{-- GIF --}}
                <div class="tab-pane fade" id="v-pills-gif" role="tabpanel" aria-labelledby="v-pills-gif-tab">
                    <div class="card">
                        <div class="card-header border-bottom">
                            <h4 class="m-0 header-title">{{ __('GIPHY') }}</h4>
                        </div>
                        <div class="card-body">
                            <span class="fs-6">*If you turn this On, Users will have GIF options in Chat &
                                Comment.</span><br>
                            <span class="fs-6">*Make sure you have added correct GIPHY keys properly.</span>
                            <form class="mt-2" id="gifSettingForm" method="POST">
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="" class="form-label">{{ __('GIF Supported') }}</label>
                                            <div class="mb-0">
                                                <input name="gif_support" type="checkbox" id="switchGifSupport"
                                                    {{ $setting->gif_support == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchGifSupport"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="giphy_key" class="form-label">{{ __('GIPHY API Key') }}</label>
                                            <input type="text" class="form-control" id="giphy_key" name="giphy_key"
                                                value="{{ $userType == 0 ? '---------' : $setting->giphy_key }}">
                                        </div>
                                    </div>
                                </div>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
                {{-- SightEngine --}}
                <div class="tab-pane fade" id="v-pills-sightEngine" role="tabpanel"
                    aria-labelledby="v-pills-sightEngine-tab">
                    <div class="card">
                        <div class="card-header border-bottom">
                            <h4 class="m-0 header-title">{{ __('SightEngine') }}</h4>
                        </div>
                        <div class="card-body">
                            <form id="contentModerationSettingForm" method="POST">
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for=""
                                                class="form-label">{{ __('Content Moderation') }}</label>
                                            <div class="mb-0">
                                                <input name="is_content_moderation" type="checkbox"
                                                    id="switchContentModeration"
                                                    {{ $setting->is_content_moderation == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchContentModeration"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="sight_engine_api_user"
                                                class="form-label">{{ __('API User') }}</label>
                                            <input type="text" class="form-control" id="sight_engine_api_user"
                                                name="sight_engine_api_user"
                                                value="{{ $userType == 0 ? '---------' : $setting->sight_engine_api_user }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="sight_engine_api_secret"
                                                class="form-label">{{ __('API Secret') }}</label>
                                            <input type="text" class="form-control" id="sight_engine_api_secret"
                                                name="sight_engine_api_secret"
                                                value="{{ $userType == 0 ? '---------' : $setting->sight_engine_api_secret }} ">
                                        </div>
                                    </div>

                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="sight_engine_image_workflow_id"
                                                class="form-label">{{ __('Image Workflow ID') }}</label>
                                            <input type="text" class="form-control"
                                                id="sight_engine_image_workflow_id" name="sight_engine_image_workflow_id"
                                                value="{{ $userType == 0 ? '---------' : $setting->sight_engine_image_workflow_id }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="sight_engine_video_workflow_id"
                                                class="form-label">{{ __('Video Workflow ID') }}</label>
                                            <input type="text" class="form-control"
                                                id="sight_engine_video_workflow_id" name="sight_engine_video_workflow_id"
                                                value="{{ $userType == 0 ? '---------' : $setting->sight_engine_video_workflow_id }}">
                                        </div>
                                    </div>

                                </div>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
                {{-- Onboarding --}}
                <div class="tab-pane fade" id="v-pills-onBoarding" role="tabpanel"
                    aria-labelledby="v-pills-onBoarding-tab">
                    <div class="card">
                        <div class="card-header d-flex align-items-center border-bottom">
                            <h4 class="m-0 header-title">{{ __('Onboarding') }}</h4>
                            <a data-bs-toggle="modal" data-bs-target="#addOnBoardingScreenModal"
                                class="btn btn-dark ms-auto">{{ __('Add Onboarding') }}</a>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table id="onboardingScreenTable"
                                    class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                                    <thead class="table-light">
                                        <tr>
                                            <th> {{ __('Sortable') }}</th>
                                            <th> {{ __('Position') }}</th>
                                            <th>{{ __('Image') }}</th>
                                            <th>{{ __('Details') }}</th>
                                            <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                                        </tr>
                                    </thead>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
                {{-- Report Reasons --}}
                <div class="tab-pane fade" id="v-pills-reportReasons" role="tabpanel"
                    aria-labelledby="v-pills-reportReasons-tab">
                    <div class="card">
                        <div class="card-header d-flex align-items-center border-bottom">
                            <h4 class="m-0 header-title">{{ __('Report Reasons') }}</h4>
                            <a data-bs-toggle="modal" data-bs-target="#addReportReasonModal"
                                class="btn btn-dark ms-auto">{{ __('Add Report Reason') }}</a>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive smallSearchBar">
                                <table id="reportReasonsTable"
                                    class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                                    <thead class="table-light">
                                        <tr>
                                            <th>{{ __('Title') }}</th>
                                            <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                                        </tr>
                                    </thead>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
                {{-- Withdrawal Gateways --}}
                <div class="tab-pane fade" id="v-pills-withdrawalGateways" role="tabpanel"
                    aria-labelledby="v-pills-withdrawalGateways-tab">
                    <div class="card">
                        <div class="card-header d-flex align-items-center border-bottom">
                            <h4 class="m-0 header-title">{{ __('Withdrawal Gateways') }}</h4>
                            <a data-bs-toggle="modal" data-bs-target="#addWithdrawalGatewayModal"
                                class="btn btn-dark ms-auto">{{ __('Add Withdrawal Gateways') }}</a>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive smallSearchBar">
                                <table id="withdrawalGatewayTable"
                                    class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                                    <thead class="table-light">
                                        <tr>
                                            <th>{{ __('Title') }}</th>
                                            <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                                        </tr>
                                    </thead>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
                {{-- DeepAR Settings --}}
                <div class="tab-pane fade" id="v-pills-deepar" role="tabpanel" aria-labelledby="v-pills-deepar-tab">
                    <div class="card">
                        <div class="card-header d-flex align-items-center border-bottom">
                            <h4 class="m-0 header-title">{{ __('DeepAR Settings') }}</h4>
                        </div>
                        <div class="card-body">
                            <form class="mt-2" id="deepARSettingsForm" method="POST">
                                <div class="row">
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for=""
                                                class="form-label">{{ __('Use DeepAR Camera (Off=Simple Camera)') }}</label>
                                            <div class="mb-0">
                                                <input name="is_deepAR" type="checkbox" id="switchDeepARCamera"
                                                    {{ $setting->is_deepAR == 1 ? 'checked' : '' }}
                                                    data-switch="primary" />
                                                <label for="switchDeepARCamera"></label>
                                            </div>
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="deepar_android_key"
                                                class="form-label">{{ __('DeepAR Android Key') }}</label>
                                            <input type="text" class="form-control" id="deepar_android_key"
                                                name="deepar_android_key"
                                                value="{{ $userType == 0 ? '---------' : $setting->deepar_android_key }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4 mb-3">
                                        <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                            <label for="deepar_iOS_key"
                                                class="form-label">{{ __('DeepAR iOS Key') }}</label>
                                            <input type="text" class="form-control" id="deepar_iOS_key"
                                                name="deepar_iOS_key"
                                                value="{{ $userType == 0 ? '---------' : $setting->deepar_iOS_key }}">
                                        </div>
                                    </div>
                                </div>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                    <div class="card">
                        <div class="card-header d-flex align-items-center border-bottom">
                            <h4 class="m-0 header-title">{{ __('DeepAR Filters') }}</h4>
                            <a data-bs-toggle="modal" data-bs-target="#addDeepARFilterModal"
                                class="btn btn-dark ms-auto">{{ __('Add Filter') }}</a>
                        </div>
                        <div class="card-body">
                            <table id="deepARFiltersTable"
                                class="table table-centered table-hover w-100 dt-responsive nowrap mt-3">
                                <thead class="table-light">
                                    <tr>
                                        <th>{{ __('Image') }}</th>
                                        <th>{{ __('Title') }}</th>
                                        <th>{{ __('File') }}</th>
                                        <th style="width: 200px;" class="text-end">{{ __('Action') }}</th>
                                    </tr>
                                </thead>
                            </table>
                        </div>
                    </div>
                </div>
                {{-- Deeplinking --}}
                <div class="tab-pane fade" id="v-pills-deeplinking" role="tabpanel"
                    aria-labelledby="v-pills-deeplinking-tab">
                    <div class="card">
                        <div class="card-header border-bottom">
                            <h5 class="m-0">{{ __('Deep Linking') }}</h5>
                        </div>
                        <div class="card-body">
                            <form id="deepLinkingForm" method="POST">
                                <div class="row">
                                    <div class="col-md-4">
                                        <div class="mb-1">
                                            <label for="uri_scheme" class="form-label">{{ __('URI Schema') }} <button
                                                    type="button" class="btn btn-secondary p-0 tooltip-icon"
                                                    data-bs-trigger="focus" data-bs-toggle="popover"
                                                    data-bs-title="How to make a Scheme"
                                                    data-bs-content="Use your app name in lowercase with no spaces or special characters (e.g., shortzz, cinereel, myapp2025).">
                                                    ?
                                                </button></label>
                                            <input type="text" class="form-control" id="uri_scheme" name="uri_scheme"
                                                value="{{ $setting->uri_scheme }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="mb-1">
                                            <label for="play_store_download_link"
                                                class="form-label">{{ __('Play Store Download Link') }}</label>
                                            <input type="text" class="form-control" id="play_store_download_link"
                                                name="play_store_download_link"
                                                value="{{ $setting->play_store_download_link }}">
                                        </div>
                                    </div>
                                    <div class="col-md-4">
                                        <div class="mb-1">
                                            <label for="app_store_download_link"
                                                class="form-label">{{ __('App Store Download Link') }}</label>
                                            <input type="text" class="form-control" id="app_store_download_link"
                                                name="app_store_download_link"
                                                value="{{ $setting->app_store_download_link }}">
                                        </div>
                                    </div>
                                </div>
                                <hr>
                                <button type="submit" class="btn btn-primary">
                                    <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                        aria-hidden="true"></span>
                                    {{ __('Save') }}
                                </button>
                            </form>
                        </div>
                    </div>
                    <div class="row">
                        <div class="col-md-6">
                            <div class="card">
                                <div class="card-header border-bottom">
                                    <h5 class="m-0">{{ __('Android') }}</h5>
                                </div>
                                <div class="card-body">
                                    <form id="androidDeepLinkingForm" method="POST">
                                        <div class="row">
                                            <div class="mb-3">
                                                <label for="package_name"
                                                    class="form-label">{{ __('Package Name') }} <a href="https://docs.retrytech.com/find_bundle_id_android" target="_blank" type="button" class="btn btn-secondary p-0 tooltip-icon">
                                                    ?
                                                </a></label>
                                                <input type="text" class="form-control" id="package_name"
                                                    name="package_name" value="{{ $packageName }}">
                                            </div>
                                            <div class="mb-3">
                                                <label class="form-label">{{ __('SHA 256 Keys') }} <a href="https://docs.retrytech.com/how_to_get_sha1_key" target="_blank" type="button" class="btn btn-secondary p-0 tooltip-icon">
                                                    ?
                                                </a></label>
                                                <div id="shaContainer">
                                                    @if (!empty($sha256))
                                                        @foreach (explode(',', $sha256) as $sha)
                                                            <div class="input-group mb-2 sha-field">
                                                                <input type="text" class="form-control sha-input"
                                                                    name="sha_256[]" value="{{ trim($sha) }}">
                                                                <button type="button"
                                                                    class="btn btn-danger remove-sha">-</button>
                                                            </div>
                                                        @endforeach
                                                    @else
                                                        <div class="input-group mb-2 sha-field">
                                                            <input type="text" class="form-control sha-input"
                                                                name="sha_256[]" placeholder="Enter SHA 256">
                                                            <button type="button"
                                                                class="btn btn-danger remove-sha">-</button>
                                                        </div>
                                                    @endif
                                                </div>
                                                <button type="button" class="btn btn-sm btn-success mt-1"
                                                    id="addSha">+ Add SHA</button>
                                            </div>
                                        </div>
                                        <hr>
                                        <button type="submit" class="btn btn-primary">
                                            <span class="spinner-border spinner-border-sm me-1 spinner hide"
                                                role="status" aria-hidden="true"></span>
                                            {{ __('Save') }}
                                        </button>
                                        <button type="button" id="checkValidationOfAndroid" class="btn btn-success">
                                            {{ __('Check Validation') }}
                                        </button>

                                    </form>
                                </div>
                            </div>
                        </div>
                        <div class="col-md-6">
                            <div class="card">
                                <div class="card-header border-bottom">
                                    <h5 class="m-0">{{ __('iOS') }}</h5>
                                </div>
                                <div class="card-body">
                                    <form id="iOSDeepLinkingForm" method="POST">
                                        <div class="row">
                                            <div class="mb-3">
                                                <label for="package_name_ios"
                                                    class="form-label">{{ __('Bundle Id / Package Name') }} <a href="https://docs.retrytech.com/find_bundle_id_ios" target="_blank" type="button" class="btn btn-secondary p-0 tooltip-icon">
                                                    ?
                                                </a></label>
                                                <input type="text" class="form-control" id="package_name_ios"
                                                    name="package_name" value="{{ $iosPackageName }}" required>
                                            </div>
                                            <div class="mb-3">
                                                <label for="team_id" class="form-label">{{ __('Team Id') }} <a href="https://docs.retrytech.com/find_team_id" target="_blank" type="button" class="btn btn-secondary p-0 tooltip-icon">
                                                    ?
                                                </a></label>
                                                <input type="text" class="form-control" id="team_id" name="team_id"
                                                    value="{{ $iosTeamId }}" required>
                                            </div>
                                        </div>
                                        <hr>
                                        <button type="submit" class="btn btn-primary">
                                            <span class="spinner-border spinner-border-sm me-1 spinner hide"
                                                role="status" aria-hidden="true"></span>
                                            {{ __('Save') }}
                                        </button>

                                        <button type="button" id="checkValidationOfApple" class="btn btn-success">
                                            {{ __('Check Validation') }}
                                        </button>

                                        <hr>

                                    </form>
                                </div>
                            </div>
                        </div>

                    </div>
                </div>
                {{-- Privacy Policy --}}
                <div class="tab-pane fade" id="v-pills-privacy-policy" role="tabpanel"
                    aria-labelledby="v-pills-privacy-policy-tab">
                    <div class="card">
                        <div class="card-header border-bottom d-flex align-items-center">
                            <h4 class="m-0 header-title">{{ __('Privacy Policy') }}</h4>
                            <a href="{{ url('privacy_policy') }}" target="_blank"
                                class="btn btn-primary rounded-5 ms-2">{{ __('View') }}</a>
                        </div>
                        <div class="card-body">
                            <form id="privacyPolicyForm" method="POST">
                                <div id="privacyEditor">{!! $setting->privacy_policy !!}</div>
                                <br>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
                {{-- Terms Of Use --}}
                <div class="tab-pane fade" id="v-pills-terms" role="tabpanel" aria-labelledby="v-pills-terms-tab">
                    <div class="card">
                        <div class="card-header border-bottom d-flex align-items-center">
                            <h4 class="m-0 header-title">{{ __('Terms Of Uses') }}</h4>
                            <a href="{{ url('terms_of_uses') }}" target="_blank"
                                class="btn btn-primary rounded-5 ms-2">{{ __('View') }}</a>
                        </div>
                        <div class="card-body">
                            <form id="termsOfUsesForm" method="POST">
                                <div id="termsOfUsesEditor">{!! $setting->terms_of_uses !!}</div>
                                <br>
                                <button type="submit" class="btn btn-primary">{{ __('Save') }}</button>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    {{-- Add DeepAR Filter Modal --}}
    <div id="addDeepARFilterModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Add DeepAR Filter') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="addDeepARFilterForm" method="POST">
                    <div class="modal-body">
                        <img id="imgDeepARFilterPreview" src="{{ url('assets/img/placeholder.png') }}"
                            alt="" class="rounded" height="100" width="100">
                        <div class="my-2">
                            <label for="image" class="form-label">{{ __('Image') }}</label>
                            <input id="inputaddDeepARFilterImage" class="form-control" type="file"
                                accept="image/*" id="image" name="image" required>
                        </div>
                        <div class="my-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input class="form-control" type="text" id="title" name="title" required>
                        </div>
                        <div class="my-2">
                            <label for="filter_file" class="form-label">{{ __('Filter File') }}</label>
                            <input class="form-control" type="file" id="filter_file" name="filter_file" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Save') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Edit DeepAR Filter Modal --}}
    <div id="editDeepARFilterModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit DeepAR Filter') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="editDeepARFilterForm" method="POST">
                    <input type="hidden" name="id" id="editDeepARFilterId">
                    <div class="modal-body">
                        <img id="imgEditDeepARFilterPreview" src="{{ url('assets/img/placeholder.png') }}"
                            alt="" class="rounded" height="100" width="100">
                        <div class="my-2">
                            <label for="image" class="form-label">{{ __('Image') }}</label>
                            <input id="inputeditDeepARFilterImage" class="form-control" type="file"
                                accept="image/*" id="image" name="image">
                        </div>
                        <div class="my-2">
                            <label for="editDeepARFilterTitle" class="form-label">{{ __('Title') }}</label>
                            <input class="form-control" type="text" id="editDeepARFilterTitle" name="title"
                                required>
                        </div>
                        <div class="my-2">
                            <label for="edit_filter_file" class="form-label">{{ __('Filter File') }}</label>
                            <input class="form-control" type="file" id="edit_filter_file" name="filter_file">
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Save') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>

    {{-- Edit User Level --}}
    <div id="editUserLevelModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit User Level') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="editUserLevelForm" method="POST">
                    <input type="hidden" name="id" id="editUserLevelId">
                    <div class="modal-body">
                        <div class="mb-2">
                            <label for="edit_level" class="form-label">{{ __('Level') }}</label>
                            <input class="form-control" type="text" id="edit_level" name="level" required
                                disabled>
                        </div>
                        <div class="mb-2">
                            <label for="edit_live_comments_count" class="form-label">{{ __('No. of Comments on Live') }}</label>
                            <input class="form-control" type="number" min="0" id="edit_live_comments_count"
                                name="live_comments_count" required>
                        </div>
                        <div class="mb-2">
                            <label for="edit_host_followers_count" class="form-label">{{ __('No.of followers') }}</label>
                            <input class="form-control" type="number" min="0" id="edit_host_followers_count"
                                name="host_followers_count" required>
                        </div>
                        <div class="mb-2">
                            <label for="edit_send_gifts_count" class="form-label">{{ __('No. of Send Gifts') }}</label>
                            <input class="form-control" type="number" min="0" id="edit_send_gifts_count"
                                name="send_gifts_count" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Edit Withdrawal Gateway --}}
    <div id="editWithdrawalGatewayModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Withdrawal Gateway') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="editWithdrawalGatewayForm" method="POST">
                    <input type="hidden" name="id" id="editWithdrawalGatewayId">
                    <div class="modal-body">
                        <div class="mb-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input id="editWithdrawalGatewayTitle" class="form-control" type="text"
                                id="title" name="title" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Edit Withdrawal Gateway --}}
    <div id="editWithdrawalGatewayModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Withdrawal Gateway') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="editWithdrawalGatewayForm" method="POST">
                    <input type="hidden" name="id" id="editWithdrawalGatewayId">
                    <div class="modal-body">
                        <div class="mb-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input id="editWithdrawalGatewayTitle" class="form-control" type="text"
                                id="title" name="title" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Edit Report Reason --}}
    <div id="editReportReasonModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Report Reason') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="editReportReasonForm" method="POST">
                    <input type="hidden" name="id" id="editReportReasonId">
                    <div class="modal-body">
                        <div class="mb-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input id="editReportReasonTitle" class="form-control" type="text" id="title"
                                name="title" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Add User Level --}}
    <div id="addUserLevelModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Add User Level') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="addUserLevelForm" method="POST">
                    <div class="modal-body">
                        <div class="mb-2">
                            <label for="level" class="form-label">{{ __('Level') }}</label>
                            <input class="form-control" type="text" id="level" name="level" required>
                        </div>
                        <div class="mb-2">
                            <label for="live_comments_count" class="form-label">{{ __('No. of Comments on Live') }}</label>
                            <input class="form-control" type="number" min="0" id="live_comments_count" name="live_comments_count"
                                required>
                        </div>
                        <div class="mb-2">
                            <label for="host_followers_count" class="form-label">{{ __('No.of followers') }}</label>
                            <input class="form-control" type="number" min="0" id="host_followers_count" name="host_followers_count"
                                required>
                        </div>
                        <div class="mb-2">
                            <label for="send_gifts_count" class="form-label">{{ __('No. of Send Gifts') }}</label>
                            <input class="form-control" type="number" min="0" id="send_gifts_count" name="send_gifts_count"
                                required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Add Withdrawal Gateways --}}
    <div id="addWithdrawalGatewayModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Withdrawal Gateway') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="addWithdrawalGatewayForm" method="POST">
                    <div class="modal-body">
                        <div class="mb-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input class="form-control" type="text" id="title" name="title" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Add Report Reason --}}
    <div id="addReportReasonModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Report Reason') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="addReportReasonForm" method="POST">
                    <div class="modal-body">
                        <div class="mb-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input class="form-control" type="text" id="title" name="title" required>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Edit Onboarding Screen --}}
    <div id="editOnBoardingScreenModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Onboarding Screen') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="editOnBoardingScreenForm" method="POST">
                    <input type="hidden" name="id" id="editOnboardingScreenId">
                    <div class="modal-body">
                        <img id="imgEditOnBoradingPreview" src="{{ url('assets/img/placeholder.png') }}"
                            alt="" class="rounded" width="200">
                        <div class="my-2">
                            <label for="image" class="form-label">{{ __('Image') }}</label>
                            <input id="inputEditOnboardingImage" class="form-control" type="file"
                                accept="image/*" id="image" name="image">
                        </div>
                        <div class="mb-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input id="editOnboardingTitle" class="form-control" type="text" id="title"
                                name="title" required>
                        </div>
                        <div class="mb-2">
                            <label for="description" class="form-label">{{ __('Description') }}</label>
                            <textarea id="editOnboardingDesc" class="form-control" id="description" name="description" required></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
    {{-- Add Onboarding Screen --}}
    <div id="addOnBoardingScreenModal" class="modal fade" tabindex="-1" role="dialog"
        aria-labelledby="standard-modalLabel" aria-hidden="true">
        <div class="modal-dialog">
            <div class="modal-content">
                <div class="modal-header">
                    <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Onboarding Screen') }}</h4>
                    <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
                </div>
                <form id="addOnBoardingScreenForm" method="POST">
                    <div class="modal-body">
                        <img id="imgAddOnBoradingPreview" src="{{ url('assets/img/placeholder.png') }}"
                            alt="" class="rounded" width="200">
                        <div class="my-2">
                            <label for="image" class="form-label">{{ __('Image') }}</label>
                            <input id="inputAddOnboardingImage" class="form-control" type="file" accept="image/*"
                                id="image" name="image" required>
                        </div>
                        <div class="mb-2">
                            <label for="title" class="form-label">{{ __('Title') }}</label>
                            <input class="form-control" type="text" id="title" name="title" required>
                        </div>
                        <div class="mb-2">
                            <label for="description" class="form-label">{{ __('Description') }}</label>
                            <textarea class="form-control" id="description" name="description" required></textarea>
                        </div>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-light"
                            data-bs-dismiss="modal">{{ __('Close') }}</button>
                        <button type="submit" class="btn btn-primary">
                            <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status"
                                aria-hidden="true"></span>
                            {{ __('Submit') }}
                        </button>
                    </div>
                </form>
            </div>
        </div>
    </div>
@endsection
