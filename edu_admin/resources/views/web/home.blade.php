@extends('web.layout')

@section('title', 'Home')
@section('meta_description', optional($site)->home_hero_subtitle ?? '')

@section('content')
    @php
        $heroImage = !empty(optional($site)->home_hero_image)
            ? \App\Models\GlobalFunction::generateFileUrl($site->home_hero_image)
            : asset('assets/img/placeholder.png');
        $appStore = optional($site)->home_app_store_url;
        $playStore = optional($site)->home_play_store_url;
    @endphp

    <!-- Hero -->
    <section class="web-hero">
        <div class="web-container">
            <div class="web-hero-text">
                <h1>{{ optional($site)->home_hero_title ?: 'Welcome to ' . $appName }}</h1>
                <p>{{ optional($site)->home_hero_subtitle ?: 'Connect, go live and share your moments with the world.' }}</p>
                <div class="web-store-badges">
                    @if(!empty($playStore))
                        <a href="{{ $playStore }}" target="_blank" rel="noopener">
                            <img src="{{ asset('assets/img/playstore.png') }}" alt="Get it on Google Play">
                        </a>
                    @endif
                    @if(!empty($appStore))
                        <a href="{{ $appStore }}" target="_blank" rel="noopener">
                            <img src="{{ asset('assets/img/appstore.png') }}" alt="Download on the App Store">
                        </a>
                    @endif
                </div>
            </div>
            <div class="web-hero-img">
                <img src="{{ $heroImage }}" alt="{{ $appName }}">
            </div>
        </div>
    </section>

    <!-- Features -->
    @if($features->count())
        <section class="web-section">
            <div class="web-container">
                <div class="web-section-head">
                    <h2>{{ optional($site)->home_features_title ?: 'Why ' . $appName . '?' }}</h2>
                    @if(!empty(optional($site)->home_features_subtitle))
                        <p>{{ $site->home_features_subtitle }}</p>
                    @endif
                </div>
                <div class="web-features-grid">
                    @foreach($features as $feature)
                        <div class="web-feature-card">
                            <div class="web-feature-icon">
                                @if(!empty($feature->icon) && \Illuminate\Support\Str::contains($feature->icon, '/'))
                                    <img src="{{ \App\Models\GlobalFunction::generateFileUrl($feature->icon) }}" alt="">
                                @else
                                    <i class="{{ $feature->icon ?: 'uil-star' }}"></i>
                                @endif
                            </div>
                            <h3>{{ $feature->title }}</h3>
                            <p>{{ $feature->description }}</p>
                        </div>
                    @endforeach
                </div>
            </div>
        </section>
    @endif

    <!-- Screenshots -->
    @if($screenshots->count())
        <section class="web-section alt">
            <div class="web-container">
                <div class="web-section-head">
                    <h2>{{ optional($site)->home_screenshots_title ?: 'A peek inside' }}</h2>
                    @if(!empty(optional($site)->home_screenshots_subtitle))
                        <p>{{ $site->home_screenshots_subtitle }}</p>
                    @endif
                </div>
                <div class="web-shots-grid">
                    @foreach($screenshots as $shot)
                        <div class="web-shot">
                            <img src="{{ \App\Models\GlobalFunction::generateFileUrl($shot->image) }}" alt="Screenshot">
                        </div>
                    @endforeach
                </div>
            </div>
        </section>
    @endif

    <!-- CTA -->
    @if(!empty($playStore) || !empty($appStore))
        <section class="web-cta">
            <div class="web-container">
                <h2>Ready to get started?</h2>
                <p>Download {{ $appName }} and join the community today.</p>
                <div class="web-store-badges" style="justify-content:center;">
                    @if(!empty($playStore))
                        <a href="{{ $playStore }}" target="_blank" rel="noopener">
                            <img src="{{ asset('assets/img/playstore.png') }}" alt="Get it on Google Play">
                        </a>
                    @endif
                    @if(!empty($appStore))
                        <a href="{{ $appStore }}" target="_blank" rel="noopener">
                            <img src="{{ asset('assets/img/appstore.png') }}" alt="Download on the App Store">
                        </a>
                    @endif
                </div>
            </div>
        </section>
    @endif
@endsection
