@extends('web.layout')

@section('title', 'Privacy Policy')

@section('content')
    <section class="web-page-header">
        <div class="web-container">
            <h1>Privacy Policy</h1>
        </div>
    </section>

    <section class="web-content">
        <div class="web-container">
            <div class="web-prose">
                @if(!empty($data))
                    {!! $data !!}
                @else
                    <p class="web-empty">Content coming soon.</p>
                @endif
            </div>
        </div>
    </section>
@endsection
