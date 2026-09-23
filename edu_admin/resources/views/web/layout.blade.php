<?php
    $appName = ($appName ?? null) ?: (optional($setting ?? null)->app_name ?: 'GeoEdu');
    $site = $site ?? null;
?>
<!DOCTYPE html>
<html lang="en" dir="ltr">

<head>
    <meta charset="utf-8" />
    <title>@yield('title', $appName) | {{ $appName }}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="@yield('meta_description', $appName)" />
    <meta name="csrf-token" content="{{ csrf_token() }}">

    <link rel="shortcut icon" href="{{ asset('assets/img/favicon.png') }}">
    <link rel="preconnect" href="https://fonts.googleapis.com">
    <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <!-- Icons (unicons + remixicon, reused from admin assets) -->
    <link href="{{ asset('assets/css/icons.min.css') }}" rel="stylesheet" type="text/css" />
    <!-- Website styles -->
    <link href="{{ asset('assets/css/website.css') }}" rel="stylesheet" type="text/css" />
    @yield('styles')
</head>

<body class="web-body">

    <!-- Navbar -->
    <header class="web-navbar">
        <div class="web-container">
            <a href="{{ url('/') }}" class="web-brand">
                <img src="{{ asset('assets/img/logo-dark.png') }}" alt="{{ $appName }}"
                    onerror="this.style.display='none'">
                <span>{{ $appName }}</span>
            </a>
            <button class="web-nav-toggle" onclick="document.getElementById('webNav').classList.toggle('open')">
                <i class="uil-bars"></i>
            </button>
            <ul class="web-nav-links" id="webNav">
                <li><a href="{{ url('/') }}" class="{{ request()->is('/') ? 'active' : '' }}">Home</a></li>
                <li><a href="{{ url('about-us') }}" class="{{ request()->is('about-us') ? 'active' : '' }}">About Us</a></li>
                <li><a href="{{ url('contact-us') }}" class="{{ request()->is('contact-us') ? 'active' : '' }}">Contact Us</a></li>
                <li><a href="{{ url('privacy_policy') }}" class="{{ request()->is('privacy_policy') ? 'active' : '' }}">Privacy</a></li>
                <li><a href="{{ url('terms_of_uses') }}" class="{{ request()->is('terms_of_uses') ? 'active' : '' }}">Terms</a></li>
            </ul>
        </div>
    </header>

    <main>
        @yield('content')
    </main>

    <!-- Footer -->
    <footer class="web-footer">
        <div class="web-container">
            <div>
                <div class="web-brand">
                    <img src="{{ asset('assets/img/logo.png') }}" alt="{{ $appName }}"
                        onerror="this.style.display='none'">
                    <span>{{ $appName }}</span>
                </div>
                @if(!empty(optional($site)->contact_email))
                    <p style="margin-top:12px;"><a href="mailto:{{ $site->contact_email }}" style="color:#c9c4e8;">{{ $site->contact_email }}</a></p>
                @endif
            </div>
            <ul class="web-footer-links">
                <li><a href="{{ url('/') }}">Home</a></li>
                <li><a href="{{ url('about-us') }}">About Us</a></li>
                <li><a href="{{ url('contact-us') }}">Contact Us</a></li>
                <li><a href="{{ url('privacy_policy') }}">Privacy Policy</a></li>
                <li><a href="{{ url('terms_of_uses') }}">Terms &amp; Conditions</a></li>
            </ul>
        </div>
        <div class="web-footer-bottom web-container" style="display:block;">
            &copy; {{ date('Y') }} {{ $appName }}. All rights reserved.
        </div>
    </footer>

</body>

</html>
