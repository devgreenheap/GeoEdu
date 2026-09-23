@extends('include.app')
@section('script')
<script src="{{ asset('assets/script/diamondFaqs.js') }}"></script>
@endsection
@section('content')

<div class="card">
    <div class="card-header d-flex align-items-center border-bottom">
        <h4 class="card-title mb-0 header-title">
            {{ __('FAQs') }}
        </h4>
        <a data-bs-toggle="modal" data-bs-target="#addDiamondFaqModal" class="btn btn-dark ms-auto">{{ __('Add FAQ') }}</a>
    </div>
    <div class="card-body">
        <div class="mb-3">
            <label for="faqCategoryFilter" class="form-label">{{ __('Category Filter') }}</label>
            <select id="faqCategoryFilter" class="form-select w-auto">
                <option value="all">{{ __('All') }}</option>
                <option value="diamond">{{ __('Diamond') }}</option>
                <option value="payment">{{ __('Payment') }}</option>
                <option value="withdrawal">{{ __('Withdrawal') }}</option>
                <option value="gift">{{ __('Gift') }}</option>
                <option value="general">{{ __('General') }}</option>
            </select>
        </div>
        <div id="diamond-faq-list" class="row g-3">
            @forelse ($items as $index => $item)
            <div class="col-md-6 col-lg-4 faq-card" data-category="{{ $item->category ?? 'diamond' }}">
                <div class="card border h-100 mb-0">
                    <div class="card-body">
                        <span class="badge bg-info mb-2 text-uppercase">{{ $item->category ?? 'diamond' }}</span>
                        <h5 class="mb-2">{{ __('Q') }}{{ $index + 1 }}: {{ $item->question }}</h5>
                        <p class="mb-3">{{ $item->answer }}</p>
                        <div class="d-flex justify-content-end align-items-center">
                            <a href="#"
                                rel="{{ $item->id }}"
                                data-category="{{ $item->category ?? 'diamond' }}"
                                data-question="{{ $item->question }}"
                                data-answer="{{ $item->answer }}"
                                class="action-btn edit d-flex align-items-center justify-content-center btn border rounded-2 text-success ms-1">
                                <i class="uil-pen"></i>
                            </a>
                            <a href="#"
                                rel="{{ $item->id }}"
                                class="action-btn delete d-flex align-items-center justify-content-center btn border rounded-2 text-danger ms-1">
                                <i class='uil-trash-alt'></i>
                            </a>
                        </div>
                    </div>
                </div>
            </div>
            @empty
            <div class="col-12">
                <p class="text-muted mb-0">{{ __('No FAQ added yet.') }}</p>
            </div>
            @endforelse
        </div>
    </div>
</div>

<div id="addDiamondFaqModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Add FAQ') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="addDiamondFaqForm" method="POST">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="faq_category" class="form-label">{{ __('Category') }}</label>
                        <select class="form-select" id="faq_category" name="category" required>
                            <option value="diamond">{{ __('Diamond') }}</option>
                            <option value="payment">{{ __('Payment') }}</option>
                            <option value="withdrawal">{{ __('Withdrawal') }}</option>
                            <option value="gift">{{ __('Gift') }}</option>
                            <option value="general">{{ __('General') }}</option>
                        </select>
                    </div>
                    <div class="mb-2">
                        <label for="faq_question" class="form-label">{{ __('Question') }}</label>
                        <textarea class="form-control" id="faq_question" name="question" rows="3" required></textarea>
                    </div>
                    <div class="mb-2">
                        <label for="faq_answer" class="form-label">{{ __('Answer') }}</label>
                        <textarea class="form-control" id="faq_answer" name="answer" rows="4" required></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

<div id="editDiamondFaqModal" class="modal fade" tabindex="-1" role="dialog" aria-hidden="true">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <h4 class="modal-title">{{ __('Edit FAQ') }}</h4>
                <button type="button" class="btn-close" data-bs-dismiss="modal" aria-hidden="true"></button>
            </div>
            <form id="editDiamondFaqForm" method="POST">
                <input type="hidden" name="id" id="editDiamondFaqId">
                <div class="modal-body">
                    <div class="mb-2">
                        <label for="edit_faq_category" class="form-label">{{ __('Category') }}</label>
                        <select class="form-select" id="edit_faq_category" name="category" required>
                            <option value="diamond">{{ __('Diamond') }}</option>
                            <option value="payment">{{ __('Payment') }}</option>
                            <option value="withdrawal">{{ __('Withdrawal') }}</option>
                            <option value="gift">{{ __('Gift') }}</option>
                            <option value="general">{{ __('General') }}</option>
                        </select>
                    </div>
                    <div class="mb-2">
                        <label for="edit_faq_question" class="form-label">{{ __('Question') }}</label>
                        <textarea class="form-control" id="edit_faq_question" name="question" rows="3" required></textarea>
                    </div>
                    <div class="mb-2">
                        <label for="edit_faq_answer" class="form-label">{{ __('Answer') }}</label>
                        <textarea class="form-control" id="edit_faq_answer" name="answer" rows="4" required></textarea>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-light" data-bs-dismiss="modal">{{ __('Close') }}</button>
                    <button type="submit" class="btn btn-primary">
                        <span class="spinner-border spinner-border-sm me-1 spinner hide" role="status" aria-hidden="true"></span>
                        {{ __('Save') }}
                    </button>
                </div>
            </form>
        </div>
    </div>
</div>

@endsection
