@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/firebaseChats.js') }}"></script>
<script>
    window.firebaseChatUsers = @json($chatUsers ?? []);
</script>
@endsection
@section('content')
<style>
    .chat-autocomplete-wrap {
        position: relative;
    }

    .chat-autocomplete-list {
        position: absolute;
        top: calc(100% + 4px);
        left: 0;
        right: 0;
        z-index: 25;
        background: #fff;
        border: 1px solid #dfe3e8;
        border-radius: 8px;
        box-shadow: 0 8px 20px rgba(16, 24, 40, 0.08);
        max-height: 220px;
        overflow-y: auto;
        display: none;
    }

    .chat-autocomplete-item {
        padding: 8px 10px;
        font-size: 13px;
        cursor: pointer;
        border-bottom: 1px solid #f1f3f5;
    }

    .chat-autocomplete-item:last-child {
        border-bottom: 0;
    }

    .chat-autocomplete-item:hover {
        background: #f8fafc;
    }
</style>

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">{{ __('Firebase Chat Details') }}</h4>
    </div>
    <div class="card-body">
        <div class="live-filter-panel mb-3">
            <div class="row g-3 align-items-end">
                <div class="col-12 col-md-4">
                    <label for="filter_chat_date" class="form-label">{{ __('Date') }}</label>
                    <input type="date" id="filter_chat_date" class="form-control">
                </div>
                <div class="col-12 col-md-4">
                    <label for="filter_chat_sender" class="form-label">{{ __('Sender') }}</label>
                    <div class="chat-autocomplete-wrap">
                        <input type="text" id="filter_chat_sender" class="form-control" autocomplete="off" placeholder="{{ __('Search sender') }}">
                        <div id="filter_chat_sender_list" class="chat-autocomplete-list"></div>
                    </div>
                </div>
                <div class="col-12 col-md-4">
                    <label for="filter_chat_receiver" class="form-label">{{ __('Receiver') }}</label>
                    <div class="chat-autocomplete-wrap">
                        <input type="text" id="filter_chat_receiver" class="form-control" autocomplete="off" placeholder="{{ __('Search receiver') }}">
                        <div id="filter_chat_receiver_list" class="chat-autocomplete-list"></div>
                    </div>
                </div>
                <div class="col-12 d-flex gap-2 justify-content-end">
                    <button type="button" id="applyFirebaseChatFilters" class="btn btn-primary">{{ __('Apply Filters') }}</button>
                    <button type="button" id="resetFirebaseChatFilters" class="btn btn-light">{{ __('Reset') }}</button>
                </div>
            </div>
        </div>
        <div class="table-responsive mt-2">
            <table id="firebaseChatsTable" class="table table-centered table-hover w-100 dt-responsive mt-3">
                <thead class="table-light">
                    <tr>
                        <th>{{ __('Room') }}</th>
                        <th>{{ __('Message ID') }}</th>
                        <th>{{ __('Sender') }}</th>
                        <th>{{ __('Receiver') }}</th>
                        <th>{{ __('Type') }}</th>
                        <th>{{ __('Message') }}</th>
                        <th>{{ __('Time') }}</th>
                        <th>{{ __('Raw') }}</th>
                    </tr>
                </thead>
            </table>
        </div>
    </div>
</div>

@endsection
