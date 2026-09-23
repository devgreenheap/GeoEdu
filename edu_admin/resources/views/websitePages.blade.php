@extends('include.app')

@section('script')
    <script src="{{ asset('assets/vendor/quill/quill.js') }}"></script>
    <script src="{{ asset('assets/script/websitePages.js') }}"></script>
@endsection

@section('content')
    @php
        $heroImageUrl = !empty(optional($setting)->home_hero_image)
            ? \App\Models\GlobalFunction::generateFileUrl($setting->home_hero_image)
            : '';
    @endphp

    <div class="row">
        <div class="col-sm-2 mb-2 mb-sm-0">
            <div class="card">
                <div class="card-body p-2">
                    <div class="nav flex-column nav-pills" id="v-pills-tab" role="tablist" aria-orientation="vertical">
                        <a class="nav-link active" id="v-pills-home-tab" data-bs-toggle="pill" href="#v-pills-home"
                            role="tab">{{ __('Home Page') }}</a>
                        <a class="nav-link" id="v-pills-about-tab" data-bs-toggle="pill" href="#v-pills-about"
                            role="tab">{{ __('About Us') }}</a>
                        <a class="nav-link" id="v-pills-contact-tab" data-bs-toggle="pill" href="#v-pills-contact"
                            role="tab">{{ __('Contact Us') }}</a>
                    </div>
                </div>
            </div>
        </div>

        <div class="col-sm-10">
            <div class="tab-content" id="v-pills-tabContent">

                {{-- ============================ HOME ============================ --}}
                <div class="tab-pane fade show active" id="v-pills-home" role="tabpanel">
                    {{-- Hero + section settings --}}
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="header-title mb-0">{{ __('Home Page Content') }}</h4>
                            <a href="{{ url('/') }}" target="_blank" class="btn btn-sm btn-soft-primary">
                                <i class="uil-external-link-alt"></i> {{ __('View Site') }}
                            </a>
                        </div>
                        <div class="card-body">
                            <form id="homeContentForm" enctype="multipart/form-data">
                                @csrf
                                <h5 class="mb-3 text-primary">{{ __('Hero Section') }}</h5>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Hero Title') }}</label>
                                    <input type="text" name="home_hero_title" class="form-control"
                                        value="{{ optional($setting)->home_hero_title }}" placeholder="Welcome to our app">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Hero Subtitle') }}</label>
                                    <textarea name="home_hero_subtitle" class="form-control" rows="2"
                                        placeholder="Short tagline shown under the title">{{ optional($setting)->home_hero_subtitle }}</textarea>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Hero Image') }}</label>
                                    <input type="file" name="home_hero_image" accept="image/*" class="form-control"
                                        id="heroImageInput">
                                    <div class="mt-2">
                                        <img id="heroImagePreview" src="{{ $heroImageUrl }}"
                                            style="max-height:120px;border-radius:8px;{{ $heroImageUrl ? '' : 'display:none;' }}">
                                    </div>
                                </div>
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('Google Play URL') }}</label>
                                        <input type="url" name="home_play_store_url" class="form-control"
                                            value="{{ optional($setting)->home_play_store_url }}" placeholder="https://play.google.com/...">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('App Store URL') }}</label>
                                        <input type="url" name="home_app_store_url" class="form-control"
                                            value="{{ optional($setting)->home_app_store_url }}" placeholder="https://apps.apple.com/...">
                                    </div>
                                </div>

                                <hr>
                                <h5 class="mb-3 text-primary">{{ __('Features Section Heading') }}</h5>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Features Title') }}</label>
                                    <input type="text" name="home_features_title" class="form-control"
                                        value="{{ optional($setting)->home_features_title }}" placeholder="Why choose us?">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Features Subtitle') }}</label>
                                    <textarea name="home_features_subtitle" class="form-control" rows="2">{{ optional($setting)->home_features_subtitle }}</textarea>
                                </div>

                                <hr>
                                <h5 class="mb-3 text-primary">{{ __('Screenshots Section Heading') }}</h5>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Screenshots Title') }}</label>
                                    <input type="text" name="home_screenshots_title" class="form-control"
                                        value="{{ optional($setting)->home_screenshots_title }}" placeholder="A peek inside">
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Screenshots Subtitle') }}</label>
                                    <textarea name="home_screenshots_subtitle" class="form-control" rows="2">{{ optional($setting)->home_screenshots_subtitle }}</textarea>
                                </div>

                                <button type="submit" class="btn btn-primary">{{ __('Save Home Content') }}</button>
                            </form>
                        </div>
                    </div>

                    {{-- Features --}}
                    <div class="card">
                        <div class="card-header">
                            <h4 class="header-title mb-0">{{ __('Feature Blocks') }}</h4>
                        </div>
                        <div class="card-body">
                            <form id="addFeatureForm" class="row g-2 align-items-end mb-3">
                                @csrf
                                <div class="col-md-3">
                                    <label class="form-label">{{ __('Icon class') }}</label>
                                    <input type="text" name="icon" class="form-control" placeholder="uil-shield-check">
                                    <small class="text-muted">Unicons/Remix class e.g. <code>uil-bolt</code></small>
                                </div>
                                <div class="col-md-3">
                                    <label class="form-label">{{ __('Title') }}</label>
                                    <input type="text" name="title" class="form-control" required>
                                </div>
                                <div class="col-md-4">
                                    <label class="form-label">{{ __('Description') }}</label>
                                    <input type="text" name="description" class="form-control">
                                </div>
                                <div class="col-md-1">
                                    <label class="form-label">{{ __('Order') }}</label>
                                    <input type="number" name="sort_order" class="form-control" value="0">
                                </div>
                                <div class="col-md-1">
                                    <button type="submit" class="btn btn-success w-100">{{ __('Add') }}</button>
                                </div>
                            </form>

                            <div class="table-responsive">
                                <table class="table table-centered table-sm mb-0">
                                    <thead>
                                        <tr>
                                            <th>{{ __('Icon') }}</th>
                                            <th>{{ __('Title') }}</th>
                                            <th>{{ __('Description') }}</th>
                                            <th>{{ __('Order') }}</th>
                                            <th class="text-end">{{ __('Action') }}</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        @forelse($features as $feature)
                                            <tr>
                                                <td><i class="{{ $feature->icon ?: 'uil-star' }} font-20"></i> <small class="text-muted">{{ $feature->icon }}</small></td>
                                                <td>{{ $feature->title }}</td>
                                                <td>{{ $feature->description }}</td>
                                                <td>{{ $feature->sort_order }}</td>
                                                <td class="text-end">
                                                    <button class="btn btn-sm btn-soft-danger delete-feature"
                                                        data-id="{{ $feature->id }}"><i class="uil-trash"></i></button>
                                                </td>
                                            </tr>
                                        @empty
                                            <tr><td colspan="5" class="text-center text-muted">{{ __('No features added yet.') }}</td></tr>
                                        @endforelse
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>

                    {{-- Screenshots --}}
                    <div class="card">
                        <div class="card-header">
                            <h4 class="header-title mb-0">{{ __('Screenshots') }}</h4>
                        </div>
                        <div class="card-body">
                            <form id="addScreenshotForm" class="row g-2 align-items-end mb-3" enctype="multipart/form-data">
                                @csrf
                                <div class="col-md-5">
                                    <label class="form-label">{{ __('Image') }}</label>
                                    <input type="file" name="image" accept="image/*" class="form-control" required>
                                </div>
                                <div class="col-md-2">
                                    <label class="form-label">{{ __('Order') }}</label>
                                    <input type="number" name="sort_order" class="form-control" value="0">
                                </div>
                                <div class="col-md-2">
                                    <button type="submit" class="btn btn-success w-100">{{ __('Upload') }}</button>
                                </div>
                            </form>

                            <div class="row" id="screenshotsGrid">
                                @forelse($screenshots as $shot)
                                    <div class="col-md-2 col-4 mb-3 text-center">
                                        <img src="{{ \App\Models\GlobalFunction::generateFileUrl($shot->image) }}"
                                            style="width:100%;border-radius:8px;border:1px solid #eee;">
                                        <button class="btn btn-sm btn-soft-danger mt-1 delete-screenshot"
                                            data-id="{{ $shot->id }}"><i class="uil-trash"></i></button>
                                    </div>
                                @empty
                                    <div class="col-12 text-center text-muted">{{ __('No screenshots added yet.') }}</div>
                                @endforelse
                            </div>
                        </div>
                    </div>
                </div>

                {{-- ============================ ABOUT ============================ --}}
                <div class="tab-pane fade" id="v-pills-about" role="tabpanel">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="header-title mb-0">{{ __('About Us') }}</h4>
                            <a href="{{ url('about-us') }}" target="_blank" class="btn btn-sm btn-soft-primary">
                                <i class="uil-external-link-alt"></i> {{ __('View Page') }}
                            </a>
                        </div>
                        <div class="card-body">
                            <form id="aboutForm">
                                @csrf
                                <div id="aboutEditor">{!! optional($setting)->about_us !!}</div>
                                <button type="submit" class="btn btn-primary mt-3">{{ __('Save About Us') }}</button>
                            </form>
                        </div>
                    </div>
                </div>

                {{-- ============================ CONTACT ============================ --}}
                <div class="tab-pane fade" id="v-pills-contact" role="tabpanel">
                    <div class="card">
                        <div class="card-header d-flex justify-content-between align-items-center">
                            <h4 class="header-title mb-0">{{ __('Contact Us') }}</h4>
                            <a href="{{ url('contact-us') }}" target="_blank" class="btn btn-sm btn-soft-primary">
                                <i class="uil-external-link-alt"></i> {{ __('View Page') }}
                            </a>
                        </div>
                        <div class="card-body">
                            <form id="contactForm">
                                @csrf
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('Email') }}</label>
                                        <input type="email" name="contact_email" class="form-control"
                                            value="{{ optional($setting)->contact_email }}">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('Phone') }}</label>
                                        <input type="text" name="contact_phone" class="form-control"
                                            value="{{ optional($setting)->contact_phone }}">
                                    </div>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">{{ __('Address') }}</label>
                                    <textarea name="contact_address" class="form-control" rows="3">{{ optional($setting)->contact_address }}</textarea>
                                </div>
                                <div class="row">
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('Facebook URL') }}</label>
                                        <input type="url" name="contact_facebook" class="form-control"
                                            value="{{ optional($setting)->contact_facebook }}">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('Instagram URL') }}</label>
                                        <input type="url" name="contact_instagram" class="form-control"
                                            value="{{ optional($setting)->contact_instagram }}">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('Twitter URL') }}</label>
                                        <input type="url" name="contact_twitter" class="form-control"
                                            value="{{ optional($setting)->contact_twitter }}">
                                    </div>
                                    <div class="col-md-6 mb-3">
                                        <label class="form-label">{{ __('YouTube URL') }}</label>
                                        <input type="url" name="contact_youtube" class="form-control"
                                            value="{{ optional($setting)->contact_youtube }}">
                                    </div>
                                </div>
                                <button type="submit" class="btn btn-primary">{{ __('Save Contact Info') }}</button>
                            </form>
                        </div>
                    </div>
                </div>

            </div>
        </div>
    </div>
@endsection
