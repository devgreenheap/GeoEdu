@extends('web.layout')

@section('title', 'Contact Us')

@section('content')
    @php
        $email = optional($site)->contact_email;
        $phone = optional($site)->contact_phone;
        $address = optional($site)->contact_address;
        $fb = optional($site)->contact_facebook;
        $ig = optional($site)->contact_instagram;
        $tw = optional($site)->contact_twitter;
        $yt = optional($site)->contact_youtube;
        $hasInfo = $email || $phone || $address;
    @endphp

    <section class="web-page-header">
        <div class="web-container">
            <h1>Contact Us</h1>
        </div>
    </section>

    <section class="web-content">
        <div class="web-container">
            @if($hasInfo)
                <div class="web-contact-grid">
                    @if($email)
                        <div class="web-contact-card">
                            <div class="web-feature-icon"><i class="uil-envelope"></i></div>
                            <h3>Email</h3>
                            <a href="mailto:{{ $email }}">{{ $email }}</a>
                        </div>
                    @endif
                    @if($phone)
                        <div class="web-contact-card">
                            <div class="web-feature-icon"><i class="uil-phone"></i></div>
                            <h3>Phone</h3>
                            <a href="tel:{{ $phone }}">{{ $phone }}</a>
                        </div>
                    @endif
                    @if($address)
                        <div class="web-contact-card">
                            <div class="web-feature-icon"><i class="uil-map-marker"></i></div>
                            <h3>Address</h3>
                            <p>{!! nl2br(e($address)) !!}</p>
                        </div>
                    @endif
                </div>
            @else
                <p class="web-empty">Contact details coming soon.</p>
            @endif

            @if($fb || $ig || $tw || $yt)
                <div class="web-socials">
                    @if($fb)<a href="{{ $fb }}" target="_blank" rel="noopener" aria-label="Facebook"><i class="uil-facebook-f"></i></a>@endif
                    @if($ig)<a href="{{ $ig }}" target="_blank" rel="noopener" aria-label="Instagram"><i class="uil-instagram"></i></a>@endif
                    @if($tw)<a href="{{ $tw }}" target="_blank" rel="noopener" aria-label="Twitter"><i class="uil-twitter"></i></a>@endif
                    @if($yt)<a href="{{ $yt }}" target="_blank" rel="noopener" aria-label="YouTube"><i class="uil-youtube"></i></a>@endif
                </div>
            @endif
        </div>
    </section>
@endsection
