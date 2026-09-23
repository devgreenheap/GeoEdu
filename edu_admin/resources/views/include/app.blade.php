<!DOCTYPE html>
<html lang="en" dir="ltr" class="light">

<head>
    <meta charset="utf-8" />
    <title>{!! Session::get('app_name') !!}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta content="Greenheap Education services" name="description" />
    <meta content="vriksha" name="author" />
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <!-- App favicon -->
    <link rel="shortcut icon" href="{{ asset('assets/img/favicon.png')}}">

    <link href="{{ asset('assets/css/common.css')}}" rel="stylesheet" type="text/css" />
    <!-- Quill css -->
    <link href="{{ asset('assets/vendor/quill/quill.core.css') }}" rel="stylesheet" type="text/css" />
    <link href="{{ asset('assets/vendor/quill/quill.snow.css') }}" rel="stylesheet" type="text/css" />
    <link href="{{ asset('assets/vendor/quill/quill.bubble.css') }}" rel="stylesheet" type="text/css" />
    <!-- Datatables css -->
    <link href="{{ asset('assets/vendor/datatables.net-bs5/css/dataTables.bootstrap5.min.css') }}" rel="stylesheet" type="text/css" />
    <link href="{{ asset('assets/vendor/datatables.net-responsive-bs5/css/responsive.bootstrap5.min.css') }}" rel="stylesheet" type="text/css" />
    <!-- Theme Config Js -->
    <script src="{{ asset('assets/js/hyper-config.js')}}"></script>
    <!-- Vendor css -->
    <link href="{{ asset('assets/css/vendor.min.css')}}" rel="stylesheet" type="text/css" />
    <!-- Link Swiper's CSS -->
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.css" />
    <!-- Dropzone css -->
    <link href="{{ asset('assets/vendor/dropzone/basic.css')}}" rel="stylesheet" type="text/css" />
    <link href="{{ asset('assets/vendor/dropzone/dropzone.css')}}" rel="stylesheet" type="text/css" />
    <!-- Toast css -->
    <link href="{{ asset('assets/vendor/jquery-toast-plugin/jquery.toast.min.css')}}" rel="stylesheet">
    <!-- App css -->
    <link href="{{ asset('assets/css/app-saas.min.css')}}" rel="stylesheet" type="text/css" id="app-style" />
    <!-- Icons css -->
    <link href="{{ asset('assets/css/icons.min.css')}}" rel="stylesheet" type="text/css" />
    <!-- Responsive fixes -->
    <link href="{{ asset('assets/css/responsive-fixes.css')}}" rel="stylesheet" type="text/css" />
</head>

@php
    $isEmbedView = request()->boolean('embed');
    $currentPath = request()->path();
    $userManagementOpen = in_array($currentPath, ['users', 'liveDetails', 'restrictions', 'notifications', 'supports']);
    $userSettingOpen = in_array($currentPath, ['giftDetails', 'entryEffects', 'packageDetails', 'music', 'levelDetails', 'xpPointsSettings']);
    $settingOpen = in_array($currentPath, ['categoryDetails', 'banners', 'languages', 'setting', 'coupons']);
    $transactionsOpen = in_array($currentPath, ['diamondTransactions', 'manualPayouts']);
    $reportsOpen = in_array($currentPath, [
        'reportRevenueCommission',
        'reportPayoutControl',
        'reportLivePerformance',
        'reportUserGrowthQuality',
        'reportGiftAnalytics',
        'reportAgentStatePerformance',
        'reportModerationRisk',
    ]);
@endphp

<body>
    @if($isEmbedView)
    <style>
        .navbar-custom,
        .leftside-menu,
        .offcanvas {
            display: none !important;
        }
        .content-page {
            margin-left: 0 !important;
            padding-top: 0 !important;
        }
        .content-page .content {
            padding: 0 !important;
        }
        .content-page .container-fluid {
            padding: 8px !important;
        }
    </style>
    @endif
    <style>
        .leftside-menu {
            background: linear-gradient(180deg, #6f8f2d 0%, #88a944 52%, #d9a52d 100%) !important;
        }

        .leftside-menu .logo {
            background: #ffffff !important;
            border-bottom: 1px solid rgba(111, 143, 45, 0.18);
        }

        .leftside-menu #leftside-menu-container {
            background: transparent !important;
        }

        .leftside-menu .side-nav-link,
        .leftside-menu .side-nav-link i,
        .leftside-menu .side-nav-title,
        .leftside-menu .button-sm-hover,
        .leftside-menu .button-close-fullsidebar {
            color: rgba(255, 255, 255, 0.92) !important;
        }

        .side-nav-group-toggle {
            font-weight: 600;
        }

        .side-nav-group-toggle i {
            font-size: 1.05rem;
        }

        .side-nav .side-nav-item.menuitem-active > .side-nav-link,
        .side-nav .side-nav-item.active > .side-nav-link,
        .side-nav .side-nav-item .side-nav-link.active,
        .side-nav-second-level .side-nav-item.active > .side-nav-link,
        .side-nav-second-level .side-nav-item.menuitem-active > .side-nav-link {
            background: rgba(56, 73, 20, 0.92);
            color: #ffffff !important;
            border-radius: 10px;
        }

        .side-nav .side-nav-item.menuitem-active > .side-nav-link i,
        .side-nav .side-nav-item.active > .side-nav-link i,
        .side-nav .side-nav-item .side-nav-link.active i,
        .side-nav-second-level .side-nav-item.active > .side-nav-link i,
        .side-nav-second-level .side-nav-item.menuitem-active > .side-nav-link i {
            color: #ffffff !important;
        }

        .side-nav .side-nav-item > .side-nav-link[aria-expanded="true"] {
            background: rgba(56, 73, 20, 0.55);
            color: #ffffff !important;
            border-radius: 10px;
        }

        .side-nav .side-nav-item .side-nav-link:hover,
        .side-nav-second-level .side-nav-item .side-nav-link:hover {
            background: rgba(255, 255, 255, 0.12);
            color: #ffffff !important;
            border-radius: 10px;
        }
    </style>
    <!-- Begin page -->
    <div class="wrapper">
        <!-- ========== Topbar Start ========== -->
        @if(!$isEmbedView)
        <div class="navbar-custom">
            <div class="topbar container-fluid">
                <div class="d-flex align-items-center gap-lg-2 gap-1">
                    <!-- Topbar Brand Logo -->
                    <div class="logo-topbar">
                        <!-- Logo light -->
                        <a href="index.html" class="logo-light">
                            <span class="logo-lg">
                                <img src="{{ asset('assets/img/logo.png')}}" alt="logo" class="img-fluid">
                            </span>
                            <!-- <span class="logo-sm">
                                <img src="{{ asset('assets/img/logo-sm.png')}}" alt="small logo" class="img-fluid">
                            </span> -->
                        </a>
                        <!-- Logo Dark -->
                        <a href="index.html" class="logo-dark">
                            <span class="logo-lg">
                                <img src="{{ asset('assets/img/logo-dark.png')}}" alt="dark logo" class="img-fluid">
                            </span>
                            <!-- <span class="logo-sm">
                                <img src="{{ asset('assets/img/logo-dark-sm.png')}}" alt="small logo" class="img-fluid">
                            </span> -->
                        </a>
                    </div>
                    <!-- Sidebar Menu Toggle Button -->
                    <button class="button-toggle-menu">
                        <i class="mdi mdi-menu"></i>
                    </button>
                    <!-- Horizontal Menu Toggle Button -->
                    <button class="navbar-toggle" data-bs-toggle="collapse" data-bs-target="#topnav-menu-content">
                        <div class="lines">
                            <span></span>
                            <span></span>
                            <span></span>
                        </div>
                    </button>
                </div>
                <ul class="topbar-menu d-flex align-items-center gap-3">
                    <li class="dropdown d-lg-none">
                        <a class="nav-link dropdown-toggle arrow-none" data-bs-toggle="dropdown" href="#" role="button" aria-haspopup="false" aria-expanded="false">
                            <i class="ri-search-line font-22"></i>
                        </a>
                        <div class="dropdown-menu dropdown-menu-animated dropdown-lg p-0">
                            <form class="p-3">
                                <input type="search" class="form-control" placeholder="Search ..." aria-label="Recipient's username">
                            </form>
                        </div>
                    </li>
                    <li class="d-none d-sm-inline-block">
                        <a class="nav-link" data-bs-toggle="offcanvas" href="#theme-settings-offcanvas">
                            <i class="ri-settings-3-line font-22"></i>
                        </a>
                    </li>
                    <li class="d-none d-sm-inline-block">
                        <div class="nav-link" id="light-dark-mode" data-bs-toggle="tooltip" data-bs-placement="left" title="Theme Mode">
                            <i class="ri-moon-line font-22"></i>
                        </div>
                    </li>
                    <li class="d-none d-md-inline-block">
                        <a class="nav-link" href="" data-toggle="fullscreen">
                            <i class="ri-fullscreen-line font-22"></i>
                        </a>
                    </li>
                    <li class="dropdown">
                        <a class="nav-link dropdown-toggle arrow-none nav-user px-2" data-bs-toggle="dropdown" href="#" role="button" aria-haspopup="false" aria-expanded="false">
                            <!-- <span class="account-user-avatar">
                           <img src="{{ asset('assets/img/avatar-1.jpg')}}" alt="user-image" width="32" class="rounded-circle">
                           </span> -->
                            <span class="d-lg-flex flex-column gap-1 d-none">
                                <h5 class="my-0 text-capitalize"> {!! Session::get('username') !!}</h5>
                            </span>
                        </a>
                        <div class="dropdown-menu dropdown-menu-end dropdown-menu-animated profile-dropdown">
                            <!-- item-->
                            <a href="{{ url('setting') }}" class="dropdown-item">
                                <i class="mdi mdi-account-edit me-1"></i>
                                <span>{{ __('Settings')}}</span>
                            </a>
                            <!-- item-->
                            <a href="{{ url('logout') }}" class="dropdown-item">
                                <i class="mdi mdi-logout me-1"></i>
                                <span>{{ __('logout')}}</span>
                            </a>
                        </div>
                    </li>
                </ul>
            </div>
        </div>
        <!-- ========== Topbar End ========== -->
        <!-- ========== Left Sidebar Start ========== -->
        <div class="leftside-menu">
            <!-- Brand Logo Light -->
            <a href="{{ url('dashboard')}}" class="logo logo-light">
                <span class="logo-lg">
                    <img src="{{ asset('assets/img/logo.png')}}" alt="logo" class="img-fluid">
                </span>
                <span class="logo-sm">
                    <img src="{{ asset('assets/img/logo.png')}}" alt="logo" class="img-fluid">
                    <!-- <img src="{{ asset('assets/img/logo-sm.png')}}" alt="small logo" class="img-fluid"> -->
                </span>
            </a>
            <!-- Brand Logo Dark -->
            <a href="{{ url('dashboard')}}" class="logo logo-dark">
                <span class="logo-lg">
                    <img src="{{ asset('assets/img/logo-dark.png')}}" alt="dark logo" class="img-fluid">
                </span>
                <span class="logo-sm">
                    <img src="{{ asset('assets/img/logo-dark.png')}}" alt="dark logo" class="img-fluid">
                    <!-- <img src="{{ asset('assets/img/logo-dark-sm.png')}}" alt="small logo" class="img-fluid"> -->
                </span>
            </a>
            <!-- Sidebar Hover Menu Toggle Button -->
            <div class="button-sm-hover" data-bs-toggle="tooltip" data-bs-placement="right" title="Show Full Sidebar">
                <i class="ri-checkbox-blank-circle-line align-middle"></i>
            </div>
            <!-- Full Sidebar Menu Close Button -->
            <div class="button-close-fullsidebar">
                <i class="ri-close-fill align-middle"></i>
            </div>
            <!-- Sidebar -->
            <div class="h-100" id="leftside-menu-container" data-simplebar>
                <!-- Leftbar User -->
                {{-- <div class="leftbar-user">
                  <a href="pages-profile.html">
                      <img src="{{ asset('assets/img/avatar-1.jpg')}}" alt="user-image" height="42" class="rounded-circle shadow-sm">
                      <span class="leftbar-user-name mt-2">Dominic Keller</span>
                  </a>
                  </div> --}}
                <ul class="side-nav">
                    <li class="side-nav-title">{{ __('app')}}</li>
                    <li class="side-nav-item index">
                        <a href="{{ url('dashboard')}}" class="side-nav-link">
                            <i class="uil-home-alt"></i>
                            <span> {{ __('Dashboard')}} </span>
                        </a>
                    </li>
                    <li class="side-nav-item">
                        <a data-bs-toggle="collapse" href="#sidebarUserManagement" aria-expanded="{{ $userManagementOpen ? 'true' : 'false' }}" aria-controls="sidebarUserManagement" class="side-nav-link side-nav-group-toggle {{ $userManagementOpen ? '' : 'collapsed' }}">
                            <i class="uil-users-alt"></i>
                            <span> {{ __('User Management')}} </span>
                            <span class="menu-arrow"></span>
                        </a>
                        <div class="collapse {{ $userManagementOpen ? 'show' : '' }}" id="sidebarUserManagement">
                            <ul class="side-nav-second-level">
                                <li class="side-nav-item users">
                                    <a href="{{ url('users')}}" class="side-nav-link">
                                        <i class="uil-user"></i>
                                        <span> {{ __('Users')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item liveDetails">
                                    <a href="{{ url('liveDetails')}}" class="side-nav-link">
                                        <i class="mdi mdi-monitor-dashboard"></i>
                                        <span> {{ __('Live Details')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item restrictions">
                                    <a href="{{ url('restrictions')}}" class="side-nav-link">
                                        <i class="uil-lock"></i>
                                        <span> {{ __('Restrictions')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item notifications">
                                    <a href="{{ url('notifications')}}" class="side-nav-link">
                                        <i class="uil-bell"></i>
                                        <span> {{ __('Notifications')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item supports">
                                    <a href="{{ url('supports') }}" class="side-nav-link">
                                        <i class="uil-headphones-alt"></i>
                                        <span> {{ __('Support')}} </span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </li>
                    <li class="side-nav-item">
                        <a data-bs-toggle="collapse" href="#sidebarUserSetting" aria-expanded="{{ $userSettingOpen ? 'true' : 'false' }}" aria-controls="sidebarUserSetting" class="side-nav-link side-nav-group-toggle {{ $userSettingOpen ? '' : 'collapsed' }}">
                            <i class="ri-user-settings-line"></i>
                            <span> User Setting </span>
                            <span class="menu-arrow"></span>
                        </a>
                        <div class="collapse {{ $userSettingOpen ? 'show' : '' }}" id="sidebarUserSetting">
                            <ul class="side-nav-second-level">
                                <li class="side-nav-item giftDetails">
                                    <a href="{{ url('giftDetails')}}" class="side-nav-link">
                                        <i class="uil-gift"></i>
                                        <span> {{ __('Gifts')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item entryEffects">
                                    <a href="{{ url('entryEffects')}}" class="side-nav-link">
                                        <i class="mdi mdi-star-four-points"></i>
                                        <span> Entry effect </span>
                                    </a>
                                </li>
                                <li class="side-nav-item packageDetails">
                                    <a href="{{ url('packageDetails')}}" class="side-nav-link">
                                        <i class="mdi mdi-diamond-stone"></i>
                                        <span> package </span>
                                    </a>
                                </li>
                                <li class="side-nav-item music">
                                    <a href="{{ url('music')}}" class="side-nav-link">
                                        <i class="uil-music"></i>
                                        <span> {{ __('Music')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item levelDetails">
                                    <a href="{{ url('levelDetails') }}" class="side-nav-link">
                                        <i class="uil-layer-group"></i>
                                        <span> {{ __('Level Details')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item xpPointsSettings">
                                    <a href="{{ url('xpPointsSettings') }}" class="side-nav-link">
                                        <i class="mdi mdi-star-circle-outline"></i>
                                        <span> {{ __('XP Points Set')}} </span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </li>
                    <li class="side-nav-item websitePages">
                        <a href="{{ url('websitePages') }}" class="side-nav-link">
                            <i class="uil-globe"></i>
                            <span> {{ __('Website Pages')}} </span>
                        </a>
                    </li>
                    <li class="side-nav-item interests">
                        <a href="{{ url('interests') }}" class="side-nav-link">
                            <i class="uil-heart"></i>
                            <span> {{ __('Interests')}} </span>
                        </a>
                    </li>
                    <li class="side-nav-item">
                        <a data-bs-toggle="collapse" href="#sidebarSetting" aria-expanded="{{ $settingOpen ? 'true' : 'false' }}" aria-controls="sidebarSetting" class="side-nav-link side-nav-group-toggle {{ $settingOpen ? '' : 'collapsed' }}">
                            <i class="ri-settings-3-line"></i>
                            <span> {{ __('Setting')}}</span>
                            <span class="menu-arrow"></span>
                        </a>
                        <div class="collapse {{ $settingOpen ? 'show' : '' }}" id="sidebarSetting">
                            <ul class="side-nav-second-level">
                                <li class="side-nav-item categoryDetails">
                                    <a href="{{ url('categoryDetails')}}" class="side-nav-link">
                                        <i class="uil-list-ul"></i>
                                        <span> Business Setting </span>
                                    </a>
                                </li>
                                <li class="side-nav-item banners">
                                    <a href="{{ url('banners')}}" class="side-nav-link">
                                        <i class="uil-image"></i>
                                        <span> {{ __('Banners')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item languages">
                                    <a href="{{ url('languages') }}" class="side-nav-link ">
                                        <i class="ri-translate-2"></i>
                                        <span> App Languagage </span>
                                    </a>
                                </li>
                                <li class="side-nav-item settings">
                                    <a href="{{ url('setting') }}" class="side-nav-link">
                                        <i class="ri-settings-3-line"></i>
                                        <span> {{ __('Settings')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item coupons">
                                    <a href="{{ url('coupons')}}" class="side-nav-link">
                                        <i class="mdi mdi-ticket-percent-outline"></i>
                                        <span> Coupon </span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </li>
                    <li class="side-nav-item">
                        <a data-bs-toggle="collapse" href="#sidebarTransactions" aria-expanded="{{ $transactionsOpen ? 'true' : 'false' }}" aria-controls="sidebarTransactions" class="side-nav-link side-nav-group-toggle {{ $transactionsOpen ? '' : 'collapsed' }}">
                            <i class="ri-exchange-dollar-line"></i>
                            <span> {{ __('transactions')}}</span>
                            <span class="menu-arrow"></span>
                        </a>
                        <div class="collapse {{ $transactionsOpen ? 'show' : '' }}" id="sidebarTransactions">
                            <ul class="side-nav-second-level">
                                <li class="side-nav-item diamondTransactions">
                                    <a href="{{ url('diamondTransactions')}}" class="side-nav-link">
                                        <i class="ri-exchange-dollar-line"></i>
                                        <span> {{ __('Diamond Transactions')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item manualPayouts">
                                    <a href="{{ url('manualPayouts')}}" class="side-nav-link">
                                        <i class="uil-bill"></i>
                                        <span> {{ __('Manual Payouts')}} </span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </li>
                    <li class="side-nav-item">
                        <a data-bs-toggle="collapse" href="#sidebarReports" aria-expanded="{{ $reportsOpen ? 'true' : 'false' }}" aria-controls="sidebarReports" class="side-nav-link side-nav-group-toggle {{ $reportsOpen ? '' : 'collapsed' }}">
                            <i class="uil-chart-line"></i>
                            <span> {{ __('reports')}}</span>
                            <span class="menu-arrow"></span>
                        </a>
                        <div class="collapse {{ $reportsOpen ? 'show' : '' }}" id="sidebarReports">
                            <ul class="side-nav-second-level">
                                <li class="side-nav-item reportRevenueCommissionMenu">
                                    <a href="{{ url('reportRevenueCommission')}}" class="side-nav-link">
                                        <i class="uil-chart-line"></i>
                                        <span> {{ __('Revenue & Commission')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item reportPayoutControlMenu">
                                    <a href="{{ url('reportPayoutControl')}}" class="side-nav-link">
                                        <i class="uil-wallet"></i>
                                        <span> {{ __('Payout Control')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item reportLivePerformanceMenu">
                                    <a href="{{ url('reportLivePerformance')}}" class="side-nav-link">
                                        <i class="mdi mdi-pulse"></i>
                                        <span> {{ __('Live Performance')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item reportUserGrowthQualityMenu">
                                    <a href="{{ url('reportUserGrowthQuality')}}" class="side-nav-link">
                                        <i class="uil-users-alt"></i>
                                        <span> {{ __('User Growth & Quality')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item reportGiftAnalyticsMenu">
                                    <a href="{{ url('reportGiftAnalytics')}}" class="side-nav-link">
                                        <i class="uil-gift"></i>
                                        <span> {{ __('Gift Analytics')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item reportAgentStatePerformanceMenu">
                                    <a href="{{ url('reportAgentStatePerformance')}}" class="side-nav-link">
                                        <i class="uil-user-check"></i>
                                        <span> {{ __('Agent & State Agent')}} </span>
                                    </a>
                                </li>
                                <li class="side-nav-item reportModerationRiskMenu">
                                    <a href="{{ url('reportModerationRisk')}}" class="side-nav-link">
                                        <i class="uil-shield-check"></i>
                                        <span> {{ __('Moderation & Risk')}} </span>
                                    </a>
                                </li>
                            </ul>
                        </div>
                    </li>
                </ul>
                <div class="clearfix"></div>
            </div>
        </div>
        <!-- ========== Left Sidebar End ========== -->
        @endif
        <!-- ============================================================== -->
        <!-- Start Page Content here -->
        <!-- ============================================================== -->
        <div class="content-page">
            <div class="content">
                <!-- Start Content-->
                <div class="container-fluid">
                    <!-- start page title -->
                    <div class="row">
                        <div class="col-12">
                            <div class="page-title-box">
                                @yield('content')
                            </div>
                        </div>
                    </div>
                    <!-- end page title -->
                </div>
                <!-- container -->
            </div>
            <!-- content -->
            <!-- Footer Start -->
            {{-- <footer class="footer">
                <div class="container-fluid">
                    <div class="row">
                        <div class="col-md-6">
                            <script>
                                document.write(new Date().getFullYear())
                            </script> © RetryTech - retrytech.com
                        </div>
                    </div>
                </div>
            </footer> --}}
            <!-- end Footer -->
        </div>
        <!-- ============================================================== -->
        <!-- End Page content -->
        <!-- ============================================================== -->
    </div>
    <!-- END wrapper -->
    <!-- Theme Settings -->
    <div class="offcanvas offcanvas-end" tabindex="-1" id="theme-settings-offcanvas">
        <div class="d-flex align-items-center bg-primary p-3 offcanvas-header">
            <h5 class="text-white m-0">{{ __('Theme Settings')}}</h5>
            <button type="button" class="btn-close btn-close-white ms-auto" data-bs-dismiss="offcanvas" aria-label="Close"></button>
        </div>
        <div class="offcanvas-body p-0">
            <div data-simplebar class="h-100">
                <div class="card mb-0 p-3">
                    <h5 class="mt-0 mb-3 font-16 fw-bold">{{ __('Color Scheme')}}</h5>
                    <div class="colorscheme-cardradio">
                        <div class="row">
                            <div class="col-4">
                                <div class="form-check card-radio">
                                    <input class="form-check-input" type="radio" name="data-bs-theme" id="layout-color-light" value="light">
                                    <label class="form-check-label p-0 avatar-md w-100" for="layout-color-light">
                                        <div id="sidebar-size">
                                            <span class="d-flex h-100">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-light d-flex h-100 border-end flex-column p-1 px-2">
                                                        <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    </span>
                                                </span>
                                                <span class="flex-grow-1">
                                                    <span class="d-flex h-100 flex-column bg-white rounded-2">
                                                        <span class="bg-light d-block p-1"></span>
                                                    </span>
                                                </span>
                                            </span>
                                        </div>
                                        <div id="topnav-color" class="bg-white rounded-2 h-100">
                                            <span class="d-flex h-100 flex-column">
                                                <span class="bg-light d-flex p-1 align-items-center border-bottom border-secondary border-opacity-25">
                                                    <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-auto"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                </span>
                                                <span class="d-flex h-100 flex-column bg-white rounded-2">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </div>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Light')}}</h5>
                            </div>
                            <div class="col-4">
                                <div class="form-check card-radio">
                                    <input class="form-check-input" type="radio" name="data-bs-theme" id="layout-color-dark" value="dark">
                                    <label class="form-check-label p-0 avatar-md w-100 bg-black" for="layout-color-dark">
                                        <div id="sidebar-size">
                                            <span class="d-flex h-100">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-light d-flex h-100 flex-column p-1 px-2">
                                                        <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                        <span class="d-block border border-secondary border-opacity-25 border-3 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-secondary border-opacity-25 border-3 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-secondary border-opacity-25 border-3 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-secondary border-opacity-25 border-3 rounded w-100 mb-1"></span>
                                                    </span>
                                                </span>
                                                <span class="flex-grow-1">
                                                    <span class="d-flex h-100 flex-column">
                                                        <span class="bg-light d-block p-1"></span>
                                                    </span>
                                                </span>
                                            </span>
                                        </div>
                                        <div id="topnav-color">
                                            <span class="d-flex h-100 flex-column">
                                                <span class="bg-light-lighten d-flex p-1 align-items-center border-bottom border-opacity-25 border-primary border-opacity-25">
                                                    <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                    <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-auto"></span>
                                                    <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-1"></span>
                                                    <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-1"></span>
                                                    <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-1"></span>
                                                </span>
                                                <span class="bg-light-lighten d-block p-1"></span>
                                            </span>
                                        </div>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Dark')}}</h5>
                            </div>
                        </div>
                    </div>
                    <div id="layout-width">
                        <h5 class="my-3 font-16 fw-bold">{{ __('Layout Mode')}}</h5>
                        <div class="row">
                            <div class="col-4">
                                <div class="form-check card-radio">
                                    <input class="form-check-input" type="radio" name="data-layout-mode" id="layout-mode-fluid" value="fluid">
                                    <label class="form-check-label p-0 avatar-md w-100" for="layout-mode-fluid">
                                        <div id="sidebar-size">
                                            <span class="d-flex h-100">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-light d-flex h-100 border-end flex-column p-1 px-2">
                                                        <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    </span>
                                                </span>
                                                <span class="flex-grow-1">
                                                    <span class="d-flex h-100 flex-column rounded-2">
                                                        <span class="bg-light d-block p-1"></span>
                                                    </span>
                                                </span>
                                            </span>
                                        </div>
                                        <div id="topnav-color">
                                            <span class="d-flex h-100 flex-column">
                                                <span class="bg-light d-flex p-1 align-items-center border-bottom border-secondary border-opacity-25">
                                                    <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-auto"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                </span>
                                                <span class="bg-light d-block p-1"></span>
                                            </span>
                                        </div>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Fluid')}}</h5>
                            </div>
                            <div class="col-4" id="layout-boxed">
                                <div class="form-check card-radio">
                                    <input class="form-check-input" type="radio" name="data-layout-mode" id="layout-mode-boxed" value="boxed">
                                    <label class="form-check-label p-0 avatar-md w-100 px-2" for="layout-mode-boxed">
                                        <div id="sidebar-size" class="border-start border-end">
                                            <span class="d-flex h-100">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-light d-flex h-100 border-end flex-column p-1 px-2">
                                                        <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    </span>
                                                </span>
                                                <span class="flex-grow-1">
                                                    <span class="d-flex h-100 flex-column rounded-2">
                                                        <span class="bg-light d-block p-1"></span>
                                                    </span>
                                                </span>
                                            </span>
                                        </div>
                                        <div id="topnav-color" class="border-start border-end h-100">
                                            <span class="d-flex h-100 flex-column">
                                                <span class="bg-light d-flex p-1 align-items-center border-bottom border-secondary border-opacity-25">
                                                    <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-auto"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                </span>
                                                <span class="bg-light d-block p-1"></span>
                                            </span>
                                        </div>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Boxed')}}</h5>
                            </div>
                            <div class="col-4" id="layout-detached">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-layout-mode" id="data-layout-detached" value="detached">
                                    <label class="form-check-label p-0 avatar-md w-100" for="data-layout-detached">
                                        <span class="d-flex h-100 flex-column">
                                            <span class="bg-light d-flex p-1 align-items-center border-bottom ">
                                                <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-auto"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                            </span>
                                            <span class="d-flex h-100 p-1 px-2">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-light d-flex h-100 flex-column p-1 px-2">
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100"></span>
                                                    </span>
                                                </span>
                                            </span>
                                            <span class="bg-light d-block p-1 mt-auto px-2"></span>
                                        </span>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Detached')}}</h5>
                            </div>
                        </div>
                    </div>
                    <h5 class="my-3 font-16 fw-bold">{{ __('Topbar Color')}}</h5>
                    <div class="row">
                        <div class="col-4">
                            <div class="form-check card-radio">
                                <input class="form-check-input" type="radio" name="data-topbar-color" id="topbar-color-light" value="light">
                                <label class="form-check-label p-0 avatar-md w-100" for="topbar-color-light">
                                    <div id="sidebar-size">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="bg-light d-flex h-100 border-end  flex-column p-1 px-2">
                                                    <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </div>
                                    <div id="topnav-color">
                                        <span class="d-flex h-100 flex-column">
                                            <span class="bg-light d-flex p-1 align-items-center border-bottom border-secondary border-opacity-25">
                                                <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-auto"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                            </span>
                                            <span class="bg-light d-block p-1"></span>
                                        </span>
                                    </div>
                                </label>
                            </div>
                            <h5 class="font-14 text-center text-muted mt-2">{{ __('Light')}}</h5>
                        </div>
                        <div class="col-4" style="--ct-dark-rgb: 64,73,84;">
                            <div class="form-check card-radio">
                                <input class="form-check-input" type="radio" name="data-topbar-color" id="topbar-color-dark" value="dark">
                                <label class="form-check-label p-0 avatar-md w-100" for="topbar-color-dark">
                                    <div id="sidebar-size">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="bg-light d-flex h-100 border-end  flex-column p-1 px-2">
                                                    <span class="d-block p-1 bg-primary-lighten rounded mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-dark d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </div>
                                    <div id="topnav-color">
                                        <span class="d-flex h-100 flex-column">
                                            <span class="bg-dark d-flex p-1 align-items-center border-bottom border-secondary border-opacity-25">
                                                <span class="d-block p-1 bg-primary-lighten rounded me-1"></span>
                                                <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-auto"></span>
                                                <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-1"></span>
                                                <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-1"></span>
                                                <span class="d-block border border-primary border-opacity-25 border-3 rounded ms-1"></span>
                                            </span>
                                            <span class="bg-light d-block p-1"></span>
                                        </span>
                                    </div>
                                </label>
                            </div>
                            <h5 class="font-14 text-center text-muted mt-2">{{ __('Dark')}}</h5>
                        </div>
                        <div class="col-4">
                            <div class="form-check card-radio">
                                <input class="form-check-input" type="radio" name="data-topbar-color" id="topbar-color-brand" value="brand">
                                <label class="form-check-label p-0 avatar-md w-100" for="topbar-color-brand">
                                    <div id="sidebar-size">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="bg-light d-flex h-100 border-end  flex-column p-1 px-2">
                                                    <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-primary bg-gradient d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </div>
                                    <div id="topnav-color">
                                        <span class="d-flex h-100 flex-column">
                                            <span class="bg-primary bg-gradient d-flex p-1 align-items-center border-bottom border-secondary border-opacity-25">
                                                <span class="d-block p-1 bg-light opacity-25 rounded me-1"></span>
                                                <span class="d-block border border-3 border opacity-25 rounded ms-auto"></span>
                                                <span class="d-block border border-3 border opacity-25 rounded ms-1"></span>
                                                <span class="d-block border border-3 border opacity-25 rounded ms-1"></span>
                                                <span class="d-block border border-3 border opacity-25 rounded ms-1"></span>
                                            </span>
                                            <span class="bg-light d-block p-1"></span>
                                        </span>
                                    </div>
                                </label>
                            </div>
                            <h5 class="font-14 text-center text-muted mt-2">{{ __('Brand')}}</h5>
                        </div>
                    </div>
                    <div>
                        <h5 class="my-3 font-16 fw-bold">{{ __('Menu Color')}}</h5>
                        <div class="row">
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-menu-color" id="leftbar-color-light" value="light">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-color-light">
                                        <div id="sidebar-size">
                                            <span class="d-flex h-100">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-light d-flex h-100 border-end  flex-column p-1 px-2">
                                                        <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                        <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    </span>
                                                </span>
                                                <span class="flex-grow-1">
                                                    <span class="d-flex h-100 flex-column">
                                                        <span class="bg-light d-block p-1"></span>
                                                    </span>
                                                </span>
                                            </span>
                                        </div>
                                        <div id="topnav-color">
                                            <span class="d-flex h-100 flex-column">
                                                <span class="bg-light d-flex p-1 align-items-center border-bottom border-secondary border-opacity-25">
                                                    <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-auto"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                </span>
                                                <span class="bg-light d-block p-1"></span>
                                            </span>
                                        </div>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Light')}}</h5>
                            </div>
                            <div class="col-4" style="--ct-dark-rgb: 64,73,84;">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-menu-color" id="leftbar-color-dark" value="dark">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-color-dark">
                                        <div id="sidebar-size">
                                            <span class="d-flex h-100">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-dark d-flex h-100 flex-column p-1 px-2">
                                                        <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                        <span class="d-block border border-secondary rounded border-opacity-25 border-3 w-100 mb-1"></span>
                                                        <span class="d-block border border-secondary rounded border-opacity-25 border-3 w-100 mb-1"></span>
                                                        <span class="d-block border border-secondary rounded border-opacity-25 border-3 w-100 mb-1"></span>
                                                        <span class="d-block border border-secondary rounded border-opacity-25 border-3 w-100 mb-1"></span>
                                                    </span>
                                                </span>
                                                <span class="flex-grow-1">
                                                    <span class="d-flex h-100 flex-column">
                                                        <span class="bg-light d-block p-1"></span>
                                                    </span>
                                                </span>
                                            </span>
                                        </div>
                                        <div id="topnav-color">
                                            <span class="d-flex h-100 flex-column">
                                                <span class="bg-light d-flex p-1 align-items-center border-bottom border-secondary border-primary border-opacity-25">
                                                    <span class="d-block p-1 bg-primary-lighten rounded me-1"></span>
                                                    <span class="d-block border border-secondary rounded border-opacity-25 border-3 ms-auto"></span>
                                                    <span class="d-block border border-secondary rounded border-opacity-25 border-3 ms-1"></span>
                                                    <span class="d-block border border-secondary rounded border-opacity-25 border-3 ms-1"></span>
                                                    <span class="d-block border border-secondary rounded border-opacity-25 border-3 ms-1"></span>
                                                </span>
                                                <span class="bg-dark d-block p-1"></span>
                                            </span>
                                        </div>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Dark')}}</h5>
                            </div>
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-menu-color" id="leftbar-color-brand" value="brand">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-color-brand">
                                        <div id="sidebar-size">
                                            <span class="d-flex h-100">
                                                <span class="flex-shrink-0">
                                                    <span class="bg-primary bg-gradient d-flex h-100 flex-column p-1 px-2">
                                                        <span class="d-block p-1 bg-light-lighten rounded mb-1"></span>
                                                        <span class="d-block border opacity-25 rounded border-3 w-100 mb-1"></span>
                                                        <span class="d-block border opacity-25 rounded border-3 w-100 mb-1"></span>
                                                        <span class="d-block border opacity-25 rounded border-3 w-100 mb-1"></span>
                                                        <span class="d-block border opacity-25 rounded border-3 w-100 mb-1"></span>
                                                    </span>
                                                </span>
                                                <span class="flex-grow-1">
                                                    <span class="d-flex h-100 flex-column">
                                                        <span class="bg-light d-block p-1"></span>
                                                    </span>
                                                </span>
                                            </span>
                                        </div>
                                        <div id="topnav-color">
                                            <span class="d-flex h-100 flex-column">
                                                <span class="bg-light d-flex p-1 align-items-center border-bottom border-secondary">
                                                    <span class="d-block p-1 bg-dark-lighten rounded me-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-auto"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded ms-1"></span>
                                                </span>
                                                <span class="bg-primary bg-gradient d-block p-1"></span>
                                            </span>
                                        </div>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Brand')}}</h5>
                            </div>
                        </div>
                    </div>
                    <div id="sidebar-size">
                        <h5 class="my-3 font-16 fw-bold">{{ __('Sidebar Size')}}</h5>
                        <div class="row">
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-sidenav-size" id="leftbar-size-default" value="default">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-size-default">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="bg-light d-flex h-100 border-end  flex-column p-1 px-2">
                                                    <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Default')}}</h5>
                            </div>
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-sidenav-size" id="leftbar-size-compact" value="compact">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-size-compact">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="bg-light d-flex h-100 border-end  flex-column p-1">
                                                    <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Compact')}}</h5>
                            </div>
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-sidenav-size" id="leftbar-size-small" value="condensed">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-size-small">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="bg-light d-flex h-100 border-end flex-column" style="padding: 2px;">
                                                    <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Condensed')}}</h5>
                            </div>
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-sidenav-size" id="leftbar-size-small-hover" value="sm-hover">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-size-small-hover">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="bg-light d-flex h-100 border-end flex-column" style="padding: 2px;">
                                                    <span class="d-block p-1 bg-dark-lighten rounded mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                    <span class="d-block border border-3 border-secondary border-opacity-25 rounded w-100 mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('HoverView')}}</h5>
                            </div>
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-sidenav-size" id="leftbar-size-full" value="full">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-size-full">
                                        <span class="d-flex h-100">
                                            <span class="flex-shrink-0">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="d-block p-1 bg-dark-lighten mb-1"></span>
                                                </span>
                                            </span>
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Full Layout')}}</h5>
                            </div>
                            <div class="col-4">
                                <div class="form-check sidebar-setting card-radio">
                                    <input class="form-check-input" type="radio" name="data-sidenav-size" id="leftbar-size-fullscreen" value="fullscreen">
                                    <label class="form-check-label p-0 avatar-md w-100" for="leftbar-size-fullscreen">
                                        <span class="d-flex h-100">
                                            <span class="flex-grow-1">
                                                <span class="d-flex h-100 flex-column">
                                                    <span class="bg-light d-block p-1"></span>
                                                </span>
                                            </span>
                                        </span>
                                    </label>
                                </div>
                                <h5 class="font-14 text-center text-muted mt-2">{{ __('Fullscreen Layout')}}</h5>
                            </div>
                        </div>
                    </div>
                    <div id="layout-position">
                        <h5 class="my-3 font-16 fw-bold">{{ __('Layout Position')}}</h5>
                        <div class="btn-group radio" role="group">
                            <input type="radio" class="btn-check" name="data-layout-position" id="layout-position-fixed" value="fixed">
                            <label class="btn btn-soft-primary w-sm" for="layout-position-fixed">{{ __('Fixed')}}</label>
                            <input type="radio" class="btn-check" name="data-layout-position" id="layout-position-scrollable" value="scrollable">
                            <label class="btn btn-soft-primary w-sm ms-0" for="layout-position-scrollable">{{ __('Scrollable')}}</label>
                        </div>
                    </div>
                    <!-- <div id="sidebar-user">
                        <div class="d-flex justify-content-between align-items-center mt-3">
                            <label class="font-16 fw-bold m-0" for="sidebaruser-check">Sidebar User Info</label>
                            <div class="form-check form-switch">
                                <input type="checkbox" class="form-check-input" name="sidebar-user" id="sidebaruser-check">
                            </div>
                        </div>
                     </div> -->
                </div>
            </div>
        </div>
        <div class="offcanvas-footer border-top p-3 text-center">
            <div class="row">
                <div class="col-12">
                    <button type="button" class="btn btn-light w-100" id="reset-layout">{{ __('Reset')}}</button>
                </div>
            </div>
        </div>
    </div>
    <!-- scripts -->
    <input type="hidden" value="{{ rtrim(url('/'), '/') . '/' }}" id="appUrl">
    <input type="hidden" value="{!! Session::get('user_type') !!}" id="user_type">

    <!-- Vendor js -->
    <script src="{{ asset('assets/js/vendor.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net/js/jquery.dataTables.min.js') }}"></script>
    <script src="https://ajax.googleapis.com/ajax/libs/jqueryui/1.10.3/jquery-ui.min.js"></script>
    <script src="{{ asset('assets/vendor/datatables.net-bs5/js/dataTables.bootstrap5.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-responsive/js/dataTables.responsive.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-responsive-bs5/js/responsive.bootstrap5.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-fixedcolumns-bs5/js/fixedColumns.bootstrap5.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-fixedheader/js/dataTables.fixedHeader.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-buttons/js/dataTables.buttons.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-buttons-bs5/js/buttons.bootstrap5.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-buttons/js/buttons.html5.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-buttons/js/buttons.flash.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-buttons/js/buttons.print.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-keytable/js/dataTables.keyTable.min.js') }}"></script>
    <script src="{{ asset('assets/vendor/datatables.net-select/js/dataTables.select.min.js') }}"></script>
        <!-- Apex Charts js -->
    <script src="assets/vendor/apexcharts/apexcharts.min.js"></script>


  <!-- Swiper JS -->
    <script src="https://cdn.jsdelivr.net/npm/swiper@11/swiper-bundle.min.js"></script>

    <!-- Datatable Demo app js -->
    <script src="{{ asset('assets/js/pages/demo.datatable-init.js') }}"></script>
    <!-- App js -->
    <script src="{{ asset('assets/js/app.min.js') }}"></script>
    <script src="{{ asset('assets/js/app.js') }}"></script>
    <!-- Toast Plugin js -->
    <script src="{{ asset('assets/vendor/jquery-toast-plugin/jquery.toast.min.js') }}"></script>
    <script src="{{ asset('assets/js/pages/demo.toastr.js') }}"></script>

    <!-- Dropzone File Upload js -->
    <script src="{{ asset('assets/vendor/dropzone/dropzone-min.js') }}"></script>
    <!-- File Upload Demo js -->
    <script src="{{ asset('assets/js/ui/component.fileupload.js') }}"></script>

    <!-- Login js -->
    <script src="{{ asset('assets/script/login.js') }}"></script>
    @yield('script')
</body>

</html>
