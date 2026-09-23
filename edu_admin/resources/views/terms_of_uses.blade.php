@extends('web.layout')

@section('title', 'Terms & Conditions')

@section('content')
    <section class="web-page-header">
        <div class="web-container">
            <h1>Terms &amp; Conditions</h1>
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
