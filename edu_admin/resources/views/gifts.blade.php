@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/gifts.js') }}"></script>

<script>

</script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Gifts')}}
        </h4>
        <a data-bs-toggle="modal" data-bs-target="#addGiftModal" class="btn btn-dark ms-auto">{{ __('Add Gift')}}</a>
    </div>
    <div class="card-body">
        <div id="gift-list" class="row">
            {{-- Gifts --}}
            @foreach ($gifts as $gift)
            <div class="col-md-2">
                <div class="card gift-card text-center">
                    <div class="card-body">
                    <div class="gift-img">
                        <img src="{{ \App\Models\GlobalFunction::generateFileUrl($gift->image) ?: ($baseUrl . $gift->image) }}" onerror="this.onerror=null;this.src='{{ asset('assets/img/placeholder.png') }}';" alt="" class="img-fluid">
                    </div>
                    <h6 class="mb-1">{{ $gift->title ?: '(No title)' }}</h6>
                    <h5> {{$gift->coin_price}} {{__('Diamonds')}} </h5>
                    <p class="mb-1 text-muted">{{ $gift->category->name ?? '-' }}</p>
                    <p class="mb-1">
                        @if(!empty($gift->animation_url))
                            <span class="badge bg-success">{{ __('Animated') }}</span>
                        @endif
                        @if(!empty($gift->sound_url))
                            <span class="badge bg-info">{{ __('Sound') }}</span>
                        @endif
                    </p>
                    <div class="gift-card-action">
                        <div class='d-flex justify-content-center align-items-center'>
                            <a href="#"
                               data-gifturl="{{ \App\Models\GlobalFunction::generateFileUrl($gift->image) ?: ($baseUrl . $gift->image) }}"
                               data-title="{{ $gift->title }}"
                               data-coinprice="{{$gift->coin_price}}"
                               data-categoryid="{{ $gift->gift_category_id }}"
                               data-animationurl="{{ !empty($gift->animation_url) ? (\App\Models\GlobalFunction::generateFileUrl($gift->animation_url) ?: ($baseUrl . $gift->animation_url)) : '' }}"
                               data-animationname="{{ !empty($gift->animation_url) ? basename($gift->animation_url) : '' }}"
                               data-soundurl="{{ !empty($gift->sound_url) ? (\App\Models\GlobalFunction::generateFileUrl($gift->sound_url) ?: ($baseUrl . $gift->sound_url)) : '' }}"
                               data-soundname="{{ !empty($gift->sound_url) ? basename($gift->sound_url) : '' }}"
                               rel="{{$gift->id}}"
                               class="action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1">
                                <i class="uil-pen"></i>
                            </a>
                            <a href="#" rel="{{$gift->id}}" class="action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1">
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
<div id="addGiftModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Add Gift')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addGiftForm" method="POST" enctype="multipart/form-data">
                <div class="modal-body">
                    <img id="imgAddGiftPreview" src="{{ url('assets/img/placeholder.png')}}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="inputAddGiftImage" class="form-label">{{ __('Image (thumbnail)')}}</label>
                        <input id="inputAddGiftImage" class="form-control" type="file" accept="image/*,.svg" name="image" required>
                    </div>
                    <div class="mb-3">
                        <label for="addGiftTitle" class="form-label">{{ __('Gift Name')}}</label>
                        <input class="form-control" type="text" id="addGiftTitle" name="title" placeholder="{{ __('e.g. Pen, Laddoo, Ring') }}">
                    </div>
                    <div class="mb-3">
                        <label for="coin_price" class="form-label">{{ __('Diamond Price')}}</label>
                        <input class="form-control" type="number" min="1" id="coin_price" name="coin_price" required>
                    </div>
                    <div class="mb-3">
                        <label for="addGiftCategoryId" class="form-label">{{ __('Gift Category') }}</label>
                        <select id="addGiftCategoryId" class="form-control" name="gift_category_id" required>
                            <option value="">{{ __('Select Gift Category') }}</option>
                            @foreach ($giftCategories as $category)
                                <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="mb-3">
                        <label for="addGiftAnimation" class="form-label">{{ __('Animation (.svga, .svg, .gif, optional)') }}</label>
                        <input class="form-control" type="file" accept=".svga,.svg,.gif,.png,.webp,.mp4" id="addGiftAnimation" name="animation">
                        <small class="text-muted d-block">{{ __('Plays room-wide when this gift is sent. Falls back to the image above if left empty.') }}</small>
                        <div id="addGiftAnimationPreview" class="mt-2 p-2 border rounded bg-light d-none">
                            <span class="badge bg-success me-1">{{ __('Selected') }}:</span>
                            <span id="addGiftAnimationFileName" class="small text-truncate"></span>
                        </div>
                    </div>
                    <div class="mb-3">
                        <label for="addGiftSound" class="form-label">{{ __('Sound (optional)') }}</label>
                        <input class="form-control" type="file" accept="audio/*,.mp3,.mp4,.wav,.m4a,.aac,.ogg" id="addGiftSound" name="sound">
                        <div id="addGiftSoundPreview" class="mt-2 p-2 border rounded bg-light d-none">
                            <span class="badge bg-info me-1">{{ __('Preview Sound') }}:</span>
                            <audio id="audioAddGiftPreview" controls class="w-100 mt-1" style="height: 32px;">
                                <source src="" type="audio/mpeg">
                            </audio>
                        </div>
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
<div id="editGiftModal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="standard-modalLabel" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title" id="standard-modalLabel">{{ __('Edit Gift')}}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editGiftForm" method="POST" enctype="multipart/form-data">
                <input type="hidden" name="id" id="editGiftId">
                <div class="modal-body">
                    <img id="imgEditGiftPreview" src="{{ url('assets/img/placeholder.png')}}" alt="" class="rounded" height="100" width="100">
                    <div class="my-3">
                        <label for="inputEditGiftImage" class="form-label">{{ __('Image')}} (Select To Edit Only)</label>
                        <input id="inputEditGiftImage" class="form-control" type="file" accept="image/*,.svg" name="image">
                    </div>
                    <div class="mb-3">
                        <label for="editGiftTitle" class="form-label">{{ __('Gift Name')}}</label>
                        <input class="form-control" type="text" id="editGiftTitle" name="title" placeholder="{{ __('e.g. Pen, Laddoo, Ring') }}">
                    </div>
                    <div class="mb-3">
                        <label for="editGiftCoinPrice" class="form-label">{{ __('Diamond Price')}}</label>
                        <input id="editGiftCoinPrice" class="form-control" type="number" min="1" name="coin_price" required>
                    </div>
                    <div class="mb-3">
                        <label for="editGiftCategoryId" class="form-label">{{ __('Gift Category') }}</label>
                        <select id="editGiftCategoryId" class="form-control" name="gift_category_id" required>
                            <option value="">{{ __('Select Gift Category') }}</option>
                            @foreach ($giftCategories as $category)
                                <option value="{{ $category->id }}">{{ $category->name }}</option>
                            @endforeach
                        </select>
                    </div>
                    <div class="mb-3">
                        <label for="editGiftAnimation" class="form-label">{{ __('Animation (.svga, .svg, .gif)') }} ({{ __('Select To Edit Only') }})</label>
                        <div id="editGiftCurrentAnimation" class="mb-2 p-2 border rounded bg-light d-none">
                            <div class="d-flex align-items-center">
                                <span class="badge bg-success me-1">{{ __('Current') }}:</span>
                                <span id="editGiftAnimationName" class="small text-truncate me-2" style="max-width: 200px;"></span>
                                <a id="editGiftAnimationLink" href="#" target="_blank" class="btn btn-sm btn-outline-primary py-0 px-2">{{ __('View') }}</a>
                            </div>
                        </div>
                        <input class="form-control" type="file" accept=".svga,.svg,.gif,.png,.webp,.mp4" id="editGiftAnimation" name="animation">
                        <small class="text-muted d-block">{{ __('Leave blank to keep current animation. Plays room-wide when sent.') }}</small>
                    </div>
                    <div class="mb-3">
                        <label for="editGiftSound" class="form-label">{{ __('Sound') }} ({{ __('Select To Edit Only') }})</label>
                        <div id="editGiftCurrentSound" class="mb-2 p-2 border rounded bg-light d-none">
                            <div class="d-flex align-items-center mb-1">
                                <span class="badge bg-info me-1">{{ __('Current Sound') }}:</span>
                                <span id="editGiftSoundName" class="small text-truncate" style="max-width: 220px;"></span>
                            </div>
                            <audio id="audioEditGiftPreview" controls class="w-100 mt-1" style="height: 32px;">
                                <source src="" type="audio/mpeg">
                            </audio>
                        </div>
                        <input class="form-control" type="file" accept="audio/*,.mp3,.mp4,.wav,.m4a,.aac,.ogg" id="editGiftSound" name="sound">
                        <small class="text-muted d-block">{{ __('Leave blank to keep current sound.') }}</small>
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
@endsection
