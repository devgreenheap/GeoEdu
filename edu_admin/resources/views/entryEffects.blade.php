@extends('include.app')
@section('script')
<script src="https://cdn.jsdelivr.net/npm/svgaplayerweb@2.3.1/build/svga.min.js"></script>
<script src="{{ asset('assets/script/entryEffects.js') }}"></script>

<script>

</script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Entry Effects')}}
        </h4>
        <a data-bs-toggle="modal" data-bs-target="#addEntryEffectModal" class="btn btn-dark ms-auto">{{ __('Add Entry Effect')}}</a>
    </div>
    <div class="card-body">
        <div id="entry-effect-list" class="row">
            {{-- Entry Effects --}}
            @foreach ($entryEffects as $entryEffect)
            @php
                $effectPath = $baseUrl . $entryEffect->image;
                $isSvga = strtolower(pathinfo($entryEffect->image ?? '', PATHINFO_EXTENSION)) === 'svga';
            @endphp
            <div class="col-md-2">
                <div class="card effect-card text-center">
                    <div class="card-body">
                    <div class="effect-img">
                        @if ($isSvga)
                            <div class="border rounded p-3 small text-muted">SVGA File</div>
                            <a href="#" data-effecturl="{{ $effectPath }}" class="btn btn-sm btn-light mt-2 preview-entry-effect">{{ __('View File') }}</a>
                        @else
                            <img src="{{ $effectPath }}" alt="" class="img-fluid">
                        @endif
                    </div>
                    <h5 class="mt-2">{{$entryEffect->title ?? '-'}}</h5>
                    <h5> {{$entryEffect->coin_price}} {{__('Diamonds')}} </h5>
                    <h6 class="mb-2 text-muted">{{ __('Duration') }}: {{$entryEffect->duration}} {{ __('hours') }}</h6>
                    <div class="effect-card-action">
                        <div class='d-flex justify-content-center align-items-center'>
                            <a href="#" data-title="{{$entryEffect->title}}" data-effecturl="{{ $effectPath }}" data-coinprice="{{$entryEffect->coin_price}}" data-duration="{{$entryEffect->duration}}" rel="{{$entryEffect->id}}" class="action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1">
                                <i class="uil-pen"></i>
                            </a>
                            <a href="#" rel="{{$entryEffect->id}}" class="action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1">
                                <i class='uil-trash-alt'></i>
                            </a>
                        </div>
                    </div>
                    </div>
                </div>
            </div>
            @endforeach

        </div>
    </div>
</div>
{{-- Add Modal --}}
<div id="addEntryEffectModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Entry Effect')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addEntryEffectForm" method="POST">
                <div class="modal-body">
                    <div class="my-3">
                        <label for="image" class="form-label">{{ __('SVGA File')}}</label>
                        <input id="inputAddEntryEffectImage" class="form-control" type="file" accept=".svga" id="image" name="image" required>
                    </div>

                    <div class="mb-3">
                        <label for="title" class="form-label">{{ __('Title')}}</label>
                        <input class="form-control" type="text" id="title" name="title" required>
                    </div>
                    <div class="mb-3">
                        <label for="coin_price" class="form-label">{{ __('Diamond Price')}}</label>
                        <input class="form-control" type="number" min="1" id="coin_price" name="coin_price" required>
                    </div>
                    <div class="mb-3">
                        <label for="duration" class="form-label">{{ __('Duration (hours)')}}</label>
                        <input class="form-control" type="number" min="1" id="duration" name="duration" required>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close')}}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save')}}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
{{-- Edit Modal --}}
<div id="editEntryEffectModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Entry Effect')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editEntryEffectForm" method="POST">
                <input type="hidden" name="id" id="editEntryEffectId">
                <div class="modal-body">
                    <a id="currentEntryEffectFileLink" href="#" class="btn btn-sm btn-light mb-3 d-none">{{ __('View Current File') }}</a>
                    <div class="my-3">
                        <label for="image" class="form-label">{{ __('SVGA File')}} ({{ __('Select To Edit Only') }})</label>
                        <input id="inputEditEntryEffectImage" class="form-control" type="file" accept=".svga" id="image" name="image">
                    </div>

                    <div class="mb-3">
                        <label for="editEntryEffectTitle" class="form-label">{{ __('Title')}}</label>
                        <input id="editEntryEffectTitle" class="form-control" type="text" name="title" required>
                    </div>
                    <div class="mb-3">
                        <label for="editEntryEffectStarPrice" class="form-label">{{ __('Diamond Price')}}</label>
                        <input id="editEntryEffectStarPrice" class="form-control" type="number" min="1" id="editEntryEffectStarPrice" name="coin_price" required>
                    </div>
                    <div class="mb-3">
                        <label for="editEntryEffectDuration" class="form-label">{{ __('Duration (hours)')}}</label>
                        <input id="editEntryEffectDuration" class="form-control" type="number" min="1" name="duration" required>
                    </div>

                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close')}}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save')}}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>
{{-- Preview Modal --}}
<div id="previewEntryEffectModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('SVGA Preview') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <div class="modal-body p-3">
                <div id="entryEffectSvgaLoading" class="text-muted mb-2 d-none">{{ __('Loading preview...') }}</div>
                <div id="entryEffectSvgaError" class="alert alert-danger d-none mb-3"></div>
                <div class="border rounded d-flex align-items-center justify-content-center p-2" style="min-height: min(260px, 45vh); max-height: 55vh; overflow: hidden;">
                    <div id="entryEffectSvgaCanvas" style="width: 100%; max-width: 420px;"></div>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
