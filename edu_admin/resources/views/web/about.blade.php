@extends('web.layout')

@section('title', 'About Us')

@section('content')
    <section class="web-page-header">
        <div class="web-container">
            <h1>About Us</h1>
        </div>
    </section>

    <section class="web-content">
        <div class="web-container">
            <div class="web-prose">
                @if(!empty(optional($site)->about_us))
                    {!! $site->about_us !!}
                @else
                    <p class="web-empty">Content coming soon.</p>
                @endif
            </div>
        </div>
    </section>
@endsection
