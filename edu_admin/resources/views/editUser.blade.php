@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/editUser.js') }}"></script>
@endsection
@section('content')

@php
use App\Models\Constants;
use App\Models\GlobalFunction;
@endphp

<input type="hidden" id="user_id" value="{{$user->id}}">

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('Edit User')}}
            {!! GlobalFunction::createUserTypeBadge($user->id) !!}
        </h4>
    </div>
    <div class="card-body">
        <span class="fs-6"><span class="text-danger">*</span> {{ __('Mandatory fields') }}</span>
        <ul class="nav nav-pills mb-3" id="edit-user-tab" role="tablist">
            <li class="nav-item" role="presentation">
                <button class="nav-link active" id="basic-tab" data-bs-toggle="pill" data-bs-target="#basic-pane" type="button" role="tab" aria-controls="basic-pane" aria-selected="true">{{ __('Basic') }}</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="star-tab" data-bs-toggle="pill" data-bs-target="#star-pane" type="button" role="tab" aria-controls="star-pane" aria-selected="false">{{ __('Star') }}</button>
            </li>
            <li class="nav-item" role="presentation">
                <button class="nav-link" id="diamond-tab" data-bs-toggle="pill" data-bs-target="#diamond-pane" type="button" role="tab" aria-controls="diamond-pane" aria-selected="false">{{ __('Diamond') }}</button>
            </li>
        </ul>

        <div class="tab-content" id="edit-user-tabContent">
            <div class="tab-pane fade show active" id="basic-pane" role="tabpanel" aria-labelledby="basic-tab" tabindex="0">
                <form id="editUserForm" method="POST">
                    <input type="hidden" name="id" value="{{$user->id}}">
                    <div class="mb-3">
                        {!! GlobalFunction::createUserDetailsColumn($user->id) !!}
                    </div>

                    <div class="row mt-3">
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="profile_photo" class="form-label">{{ __('Profile Photo')}}</label>
                                <input type="file" id="profile_photo" name="profile_photo" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="fullname" class="form-label">{{ __('Fullname')}} <span class="text-danger">*</span></label>
                                <input value="{{$user->fullname}}" type="text" id="fullname" name="fullname" class="form-control" required>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="first_name" class="form-label">{{ __('First Name')}}</label>
                                <input value="{{$user->first_name}}" type="text" id="first_name" name="first_name" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="last_name" class="form-label">{{ __('Last Name')}}</label>
                                <input value="{{$user->last_name}}" type="text" id="last_name" name="last_name" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="gender" class="form-label">{{ __('Gender')}}</label>
                                <select id="gender" name="gender" class="form-control">
                                    <option value="">{{ __('Select Gender') }}</option>
                                    <option value="male" {{ strtolower($user->gender ?? '') === 'male' ? 'selected' : '' }}>{{ __('Male') }}</option>
                                    <option value="female" {{ strtolower($user->gender ?? '') === 'female' ? 'selected' : '' }}>{{ __('Female') }}</option>
                                    <option value="other" {{ strtolower($user->gender ?? '') === 'other' ? 'selected' : '' }}>{{ __('Other') }}</option>
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="date_of_birth" class="form-label">{{ __('Date Of Birth')}}</label>
                                <input value="{{$user->date_of_birth}}" type="date" id="date_of_birth" name="date_of_birth" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="country" class="form-label">{{ __('Country')}}</label>
                                <select id="country" name="country" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select Country') }}</option>
                                    @foreach($countries as $country)
                                    <option value="{{ $country->name }}" {{ trim((string) $user->country) === trim((string) $country->name) ? 'selected' : '' }}>{{ $country->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="state" class="form-label">{{ __('State')}}</label>
                                <select id="state" name="state" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select State') }}</option>
                                    @foreach($states as $state)
                                    <option value="{{ $state->name }}" data-country-name="{{ $state->country?->name }}" {{ trim((string) $user->state) === trim((string) $state->name) ? 'selected' : '' }}>{{ $state->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="city" class="form-label">{{ __('City')}}</label>
                                <input value="{{$user->city}}" type="text" id="city" name="city" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="zipcode" class="form-label">{{ __('Zipcode')}}</label>
                                <input value="{{$user->zipcode}}" type="text" id="zipcode" name="zipcode" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="address1" class="form-label">{{ __('Address 1')}}</label>
                                <input value="{{$user->address1}}" type="text" id="address1" name="address1" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-6 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="address2" class="form-label">{{ __('Address 2')}}</label>
                                <input value="{{$user->address2}}" type="text" id="address2" name="address2" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="college_name" class="form-label">{{ __('College Name')}}</label>
                                <input value="{{$user->college_name}}" type="text" id="college_name" name="college_name" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="degree" class="form-label">{{ __('Degree')}}</label>
                                <input value="{{$user->degree}}" type="text" id="degree" name="degree" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="full_qualification" class="form-label">{{ __('Full Qualification')}}</label>
                                <input value="{{$user->full_qualification}}" type="text" id="full_qualification" name="full_qualification" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="role" class="form-label">{{ __('Role')}}</label>
                                <input value="{{$user->role}}" type="text" id="role" name="role" class="form-control">
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="identity" class="form-label">{{ __('Identifier')}}</label>
                                <input type="text" value="{{$user->identity}}" id="identity" class="form-control" readonly disabled>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="username" class="form-label">{{ __('Username')}} <span class="text-danger">*</span></label>
                                <input type="text" value="{{$user->username}}" id="username" name="username" class="form-control" required>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="user_email" class="form-label">{{ __('Email')}}</label>
                                <input type="text" value="{{$user->identity}}" id="user_email" class="form-control" readonly disabled>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="user_mobile_no" class="form-label">{{ __('Mobile')}}</label>
                                <div class="d-flex">
                                    <select name="mobile_country_code" class="form-control country-code-field">
                                        @foreach ($phoneCountryCodes as $item)
                                        <option {{$user->mobile_country_code == $item['phone_code'] ? 'selected' : ''}} value="{{$item['phone_code']}}">{{$item['country_code']}} (+{{$item['phone_code']}})</option>
                                        @endforeach
                                    </select>
                                    <input min="1" value="{{$user->user_mobile_no}}" type="number" id="user_mobile_no" name="user_mobile_no" class="form-control mobile-field">
                                </div>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="bio" class="form-label">{{ __('Bio')}}</label>
                                <textarea id="bio" name="bio" class="form-control">{{$user->bio}}</textarea>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="category_id" class="form-label">{{ __('Category')}}</label>
                                <select id="category_id" name="category_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select Category') }}</option>
                                    @foreach($categories as $category)
                                    <option value="{{ $category->id }}" {{ intval($user->category_id) === intval($category->id) ? 'selected' : '' }}>{{ $category->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="sub_category_id" class="form-label">{{ __('Sub Category')}}</label>
                                <select id="sub_category_id" name="sub_category_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select Sub Category') }}</option>
                                    @foreach($subCategories as $subCategory)
                                    <option value="{{ $subCategory->id }}" data-category-id="{{ $subCategory->category_id }}" {{ intval($user->sub_category_id) === intval($subCategory->id) ? 'selected' : '' }}>{{ $subCategory->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="topic_id" class="form-label">{{ __('Topic')}}</label>
                                <select id="topic_id" name="topic_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select Topic') }}</option>
                                    @foreach($topics as $topic)
                                    <option value="{{ $topic->id }}" data-sub-category-id="{{ $topic->sub_category_id }}" {{ intval($user->topic_id) === intval($topic->id) ? 'selected' : '' }}>{{ $topic->name }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="language_id" class="form-label">{{ __('Language')}}</label>
                                <select id="language_id" name="language_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select Language') }}</option>
                                    @foreach($languages as $language)
                                    <option value="{{ $language->id }}" {{ intval($user->language_id) === intval($language->id) ? 'selected' : '' }}>{{ $language->title ?? $language->code }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="level_id" class="form-label">{{ __('Level')}}</label>
                                <select id="level_id" name="level_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select Level') }}</option>
                                    @foreach($levels as $level)
                                    <option value="{{ $level->id }}" {{ intval($user->level_id) === intval($level->id) ? 'selected' : '' }}>{{ $level->level }}</option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="agent_id" class="form-label">{{ __('Agent') }}</label>
                                <select id="agent_id" name="agent_id" class="form-control select2 remove-searchbar" data-toggle="select2">
                                    <option value="">{{ __('Select Agent') }}</option>
                                    @foreach($agents as $agent)
                                    <option value="{{ $agent->id }}" {{ intval($user->agent_id) === intval($agent->id) ? 'selected' : '' }}>
                                        {{ $agent->username }}{{ !empty($agent->fullname) ? (' - '.$agent->fullname) : '' }}
                                    </option>
                                    @endforeach
                                </select>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label class="form-label">{{ __('Adult')}}</label>
                                <div class="mb-0">
                                    <input name="is_adult" type="checkbox" id="switchIsAdult" {{$user->is_adult == 1? 'checked' : ''}} data-switch="primary"/>
                                    <label for="switchIsAdult"></label>
                                </div>
                            </div>
                        </div>
                    </div>

                    @if ($user->is_dummy == Constants::userDummy)
                    <h5>{{__('Dummy User Functions')}}</h5>
                    <div class="row mt-3">
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label for="password" class="form-label">{{ __('Password')}} <span class="text-danger">*</span></label>
                                <input type="text" value="{{$user->password}}" id="password" name="password" class="form-control" required>
                            </div>
                        </div>
                        <div class="col-md-3 mb-3">
                            <div class="mb-0 bg-secondary-lighten border p-2 rounded-3">
                                <label class="form-label">{{ __('Verified')}}</label>
                                <div class="mb-0">
                                    <input name="is_verify" type="checkbox" id="switchIsVerify" {{$user->is_verify == 1? 'checked' : ''}} data-switch="primary"/>
                                    <label for="switchIsVerify"></label>
                                </div>
                            </div>
                        </div>
                    </div>
                    @endif

                    <button type="submit" class="btn btn-primary">{{__('Submit')}}</button>
                </form>
            </div>

            <div class="tab-pane fade" id="star-pane" role="tabpanel" aria-labelledby="star-tab" tabindex="0">
                <div class="row g-3">
                    <div class="col-lg-6">
                        <div class="card border">
                            <div class="card-body text-center">
                                <h5 class="mb-2">{{ __('Current Star Wallet') }}</h5>
                                <h2 class="text-primary mb-1">{{ number_format($user->coin_wallet ?? 0) }}</h2>
                                <p class="mb-0 text-muted">{{ __('Collected') }}: {{ number_format($user->coin_collected_lifetime ?? 0) }} | {{ __('Gifted') }}: {{ number_format($user->coin_gifted_lifetime ?? 0) }} | {{ __('Purchased') }}: {{ number_format($user->coin_purchased_lifetime ?? 0) }}</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="card border">
                            <div class="card-body">
                                <h5 class="mb-3">{{ __('Add Star') }}</h5>
                                <form id="addCoinsForm" method="POST">
                                    <input type="hidden" name="user_id" value="{{$user->id}}">
                                    <div class="mb-3">
                                        <label for="coins" class="form-label">{{ __('Stars') }} <span class="text-danger">*</span></label>
                                        <input class="form-control" type="number" min="1" id="coins" name="coins" required>
                                    </div>
                                    <button type="submit" class="btn btn-primary">
                                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                                        {{ __('Save') }}
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class="tab-pane fade" id="diamond-pane" role="tabpanel" aria-labelledby="diamond-tab" tabindex="0">
                <div class="row g-3">
                    <div class="col-lg-6">
                        <div class="card border">
                            <div class="card-body text-center">
                                <h5 class="mb-2">{{ __('Current Diamond Wallet') }}</h5>
                                <h2 class="text-primary mb-1">{{ number_format($user->diamond_wallet ?? 0) }}</h2>
                                <p class="mb-0 text-muted">{{ __('Collected') }}: {{ number_format($user->diamond_collected_lifetime ?? 0) }} | {{ __('Spent') }}: {{ number_format($user->diamond_spent_lifetime ?? 0) }} | {{ __('Purchased') }}: {{ number_format($user->diamond_purchased_lifetime ?? 0) }}</p>
                            </div>
                        </div>
                    </div>
                    <div class="col-lg-6">
                        <div class="card border">
                            <div class="card-body">
                                <h5 class="mb-3">{{ __('Add Diamond') }}</h5>
                                <form id="addDiamondsForm" method="POST">
                                    <input type="hidden" name="user_id" value="{{$user->id}}">
                                    <div class="mb-3">
                                        <label for="diamonds" class="form-label">{{ __('Diamonds') }} <span class="text-danger">*</span></label>
                                        <input class="form-control" type="number" min="1" id="diamonds" name="diamonds" required>
                                    </div>
                                    <div class="mb-3">
                                        <label for="diamond_note" class="form-label">{{ __('Note') }}</label>
                                        <textarea class="form-control" id="diamond_note" name="note"></textarea>
                                    </div>
                                    <button type="submit" class="btn btn-primary">
                                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                                        {{ __('Save') }}
                                    </button>
                                </form>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

@endsection
