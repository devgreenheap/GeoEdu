<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ $verified ? __('Verified Invoice - ') . ($invoiceNumber ?? $id) : __('Unverified Invoice Alert') }}</title>
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * {
            box-sizing: border-box;
            margin: 0;
            padding: 0;
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
        }
        body {
            background-color: #f3f4f6;
            color: #111827;
            padding: 24px 16px;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
        }
        .container {
            width: 100%;
            max-width: 760px;
        }
        /* Verification Status Banner */
        .status-badge {
            display: flex;
            align-items: center;
            padding: 16px 20px;
            border-radius: 12px;
            margin-bottom: 20px;
            box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.05);
        }
        .status-badge.verified {
            background: linear-gradient(135deg, #ecfdf5 0%, #d1fae5 100%);
            border: 1.5px solid #10b981;
            color: #065f46;
        }
        .status-badge.fake {
            background: linear-gradient(135deg, #fef2f2 0%, #fee2e2 100%);
            border: 1.5px solid #ef4444;
            color: #991b1b;
        }
        .status-icon {
            font-size: 32px;
            margin-right: 16px;
            line-height: 1;
        }
        .status-title {
            font-size: 17px;
            font-weight: 800;
            letter-spacing: -0.01em;
            margin-bottom: 3px;
        }
        .status-desc {
            font-size: 13px;
            line-height: 1.4;
            opacity: 0.9;
        }
        /* Paper Invoice Card */
        .invoice-card {
            background: #ffffff;
            border-radius: 8px;
            box-shadow: 0 10px 25px -5px rgba(0, 0, 0, 0.1), 0 8px 10px -6px rgba(0, 0, 0, 0.05);
            padding: 36px 32px;
            border: 1px solid #e5e7eb;
        }
        .invoice-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding-bottom: 12px;
            border-bottom: 1px solid #d1d5db;
        }
        .header-left {
            display: flex;
            align-items: center;
            gap: 12px;
        }
        .header-logo {
            max-height: 48px;
            max-width: 140px;
            object-fit: contain;
        }
        .header-company-name {
            font-size: 14px;
            font-weight: 700;
            color: #111827;
            max-width: 320px;
            line-height: 1.3;
        }
        .header-right {
            text-align: right;
            font-size: 12px;
        }
        .header-right .gstin-label {
            font-weight: 700;
        }
        .invoice-title {
            text-align: center;
            font-size: 17px;
            font-weight: 800;
            letter-spacing: 0.05em;
            margin: 16px 0 18px 0;
        }
        .meta-grid {
            display: flex;
            justify-content: space-between;
            font-size: 12.5px;
            margin-bottom: 18px;
        }
        .meta-col {
            display: flex;
            flex-direction: column;
            gap: 4px;
        }
        .meta-col.right {
            text-align: right;
        }
        .meta-label {
            font-weight: 700;
            color: #1f2937;
        }
        /* Table */
        .product-table {
            width: 100%;
            border-collapse: collapse;
            border: 1px solid #000000;
            margin-bottom: 14px;
        }
        .product-table th {
            background-color: #FDF4C5;
            color: #000000;
            font-weight: 700;
            font-size: 12.5px;
            padding: 8px 12px;
            border: 1px solid #000000;
            text-align: left;
        }
        .product-table th.center, .product-table td.center {
            text-align: center;
        }
        .product-table th.right, .product-table td.right {
            text-align: right;
        }
        .product-table td {
            padding: 10px 12px;
            border: 1px solid #000000;
            font-size: 13px;
        }
        .product-table .item-name {
            font-weight: 700;
            font-size: 13px;
            margin-bottom: 2px;
        }
        .product-table .item-sub {
            font-size: 11px;
            color: #4b5563;
        }
        /* Summary */
        .summary-container {
            display: flex;
            justify-content: flex-end;
            margin-bottom: 14px;
        }
        .summary-table {
            width: 260px;
            font-size: 12.5px;
        }
        .summary-row {
            display: flex;
            justify-content: space-between;
            padding: 2.5px 0;
        }
        .summary-row.total {
            border-top: 1px solid #9ca3af;
            padding-top: 5px;
            margin-top: 4px;
            font-weight: 800;
            font-size: 13.5px;
        }
        /* Amount in words */
        .amount-in-words {
            text-align: center;
            font-style: italic;
            font-weight: 700;
            font-size: 12px;
            color: #1f2937;
            margin: 14px 0 20px 0;
        }
        /* Signatory */
        .signatory-section {
            display: flex;
            justify-content: flex-end;
            margin-bottom: 16px;
        }
        .signatory-box {
            text-align: center;
            width: 160px;
        }
        .signatory-img {
            max-height: 40px;
            max-width: 130px;
            margin-bottom: 4px;
            object-fit: contain;
        }
        .signatory-name {
            font-style: italic;
            font-size: 14px;
            color: #374151;
            margin-bottom: 4px;
        }
        .signatory-label {
            font-size: 11px;
            font-weight: 700;
            border-top: 1px solid #000;
            padding-top: 3px;
        }
        /* Declaration */
        .declaration-title {
            font-size: 11.5px;
            font-weight: 700;
            margin-bottom: 4px;
        }
        .declaration-bar {
            height: 4px;
            background-color: #222222;
            margin-bottom: 6px;
        }
        .declaration-text {
            font-size: 9.5px;
            line-height: 1.45;
            color: #374151;
            text-align: justify;
            margin-bottom: 18px;
        }
        /* Footer */
        .invoice-footer {
            border-top: 1px solid #d1d5db;
            padding-top: 10px;
            text-align: center;
            font-size: 10.5px;
            color: #374151;
            line-height: 1.5;
        }
        .actions-bar {
            margin-top: 16px;
            display: flex;
            justify-content: center;
            gap: 12px;
        }
        .btn-print {
            background-color: #1f2937;
            color: #ffffff;
            border: none;
            padding: 10px 20px;
            border-radius: 8px;
            font-weight: 600;
            font-size: 13px;
            cursor: pointer;
            text-decoration: none;
            display: inline-flex;
            align-items: center;
            gap: 6px;
        }
        .btn-print:hover {
            background-color: #111827;
        }
        @media print {
            body {
                background: #fff;
                padding: 0;
            }
            .status-badge, .actions-bar {
                display: none !important;
            }
            .invoice-card {
                box-shadow: none;
                border: none;
                padding: 0;
            }
        }
    </style>
</head>
<body>
    <div class="container">
        @if($verified)
            {{-- VERIFIED AUTHENTIC BADGE --}}
            <div class="status-badge verified">
                <div class="status-icon">✓</div>
                <div>
                    <div class="status-title">{{ __('VERIFIED AUTHENTIC INVOICE') }}</div>
                    <div class="status-desc">
                        {{ __('This invoice is officially verified and registered in the records of') }} <strong>{{ $settings->invoice_company_name ?? 'Greenheap Gold and Silver Jewellery Private Limited' }}</strong>.
                        <br>{{ __('Verified on:') }} {{ date('d M Y, h:i A') }}
                    </div>
                </div>
            </div>

            {{-- OFFICIAL INVOICE PAPER --}}
            <div class="invoice-card" id="printableInvoice">
                {{-- 1. Top Header --}}
                <div class="invoice-header">
                    <div class="header-left">
                        @if(!empty($settings->invoice_company_logo))
                            <img src="{{ \App\Models\GlobalFunction::generateFileUrl($settings->invoice_company_logo) }}" alt="Logo" class="header-logo">
                        @else
                            <img src="{{ asset('assets/img/app_logo.png') }}" alt="Logo" class="header-logo" onerror="this.style.display='none'">
                        @endif
                        <div class="header-company-name">
                            {{ $settings->invoice_company_name ?? 'Greenheap Gold and Silver Jewellery Private Limited' }}
                        </div>
                    </div>
                    <div class="header-right">
                        <div class="gstin-label">{{ __('GSTIN:') }}</div>
                        <div>{{ $settings->invoice_gstin ?? '33AALCG2057M1ZE' }}</div>
                    </div>
                </div>

                {{-- 2. Title --}}
                <div class="invoice-title">{{ __('PRODUCT INVOICE') }}</div>

                {{-- 3. Customer & Bill Info Grid --}}
                <div class="meta-grid">
                    <div class="meta-col">
                        <div>
                            <span class="meta-label">{{ __('Mr./Ms :') }}</span>
                            <span>{{ $user->fullname ?: ($user->username ?: 'Customer') }}</span>
                        </div>
                        <div>
                            <span class="meta-label">{{ __('Mobile No :') }}</span>
                            <span>{{ $user->mobile ?: '-' }}</span>
                        </div>
                    </div>
                    <div class="meta-col right">
                        <div>
                            <span class="meta-label">{{ __('Bill No :') }}</span>
                            <span>{{ $invoiceNumber }}</span>
                        </div>
                        <div>
                            <span class="meta-label">{{ __('Bill Date / Time :') }}</span>
                            <span>{{ $transaction->created_at ? date('Y-m-d H:i:s', strtotime($transaction->created_at)) : date('Y-m-d H:i:s') }}</span>
                        </div>
                    </div>
                </div>

                {{-- 4. Product Details Table --}}
                <table class="product-table">
                    <thead>
                        <tr>
                            <th style="width: 55%;">{{ __('Product Details') }}</th>
                            <th class="center" style="width: 15%;">{{ __('Quantity') }}</th>
                            <th class="right" style="width: 30%;">{{ __('Amount') }}</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>
                                <div class="item-name">{{ $productName }}</div>
                                <div class="item-sub">
                                    {{ __('Product ID:') }} {{ $productId }} &nbsp;|&nbsp; {{ __('HSN / SAC:') }} {{ $settings->invoice_hsn_code ?? '7113' }}
                                </div>
                            </td>
                            <td class="center">1</td>
                            <td class="right">{{ number_format($productDiscPrice, 2) }}</td>
                        </tr>
                    </tbody>
                </table>

                {{-- 5. Right-Aligned Financial Breakdown --}}
                <div class="summary-container">
                    <div class="summary-table">
                        <div class="summary-row">
                            <span>{{ __('Sub Total:') }}</span>
                            <span>{{ number_format($productDiscPrice, 2) }}</span>
                        </div>
                        @if($makingChargeAmount > 0)
                        <div class="summary-row">
                            <span>{{ __('Making Charge (') }}{{ number_format($makingChargePercent, 1) }}{{ __('%) :') }}</span>
                            <span>{{ number_format($makingChargeAmount, 2) }}</span>
                        </div>
                        @endif
                        @if($handlingFee > 0)
                        <div class="summary-row">
                            <span>{{ __('Shipping / Handling Cost :') }}</span>
                            <span>{{ number_format($handlingFee, 2) }}</span>
                        </div>
                        @endif
                        <div class="summary-row">
                            <span>{{ __('GST (') }}{{ number_format($silverJewelGstPercent, 1) }}{{ __('%) :') }}</span>
                            <span>{{ number_format($gstAmount, 2) }}</span>
                        </div>
                        <div class="summary-row">
                            <span>{{ __('Discount :') }}</span>
                            <span>{{ number_format($discount, 2) }}</span>
                        </div>
                        <div class="summary-row total">
                            <span>{{ __('Total :') }}</span>
                            <span>{{ number_format($finalAmount, 2) }}</span>
                        </div>
                    </div>
                </div>

                {{-- 6. Total in Words --}}
                <div class="amount-in-words">
                    [Rupees {{ ucwords(\App\Models\GlobalFunction::numberToWords($finalAmount) ?? 'Zero') }} Only]
                </div>

                {{-- 7. Authorized Signatory & QR Code --}}
                <div class="signatory-section">
                    <div class="signatory-box">
                        @if(!empty($settings->invoice_signature_image))
                            <img src="{{ \App\Models\GlobalFunction::generateFileUrl($settings->invoice_signature_image) }}" alt="Signature" class="signatory-img">
                        @else
                            <div class="signatory-name">{{ $settings->invoice_signatory_name ?? 'Authorized Signatory' }}</div>
                        @endif
                        <div class="signatory-label">{{ __('Authorized Signatory') }}</div>
                        <div style="margin-top: 8px;">
                            <img src="https://api.qrserver.com/v1/create-qr-code/?size=90x90&data={{ urlencode(url('/verify-invoice/' . ($transaction->id ?? $id))) }}" alt="QR Code" style="width: 75px; height: 75px; display: inline-block;">
                        </div>
                        <div style="font-size: 9.5px; color: #6b7280; margin-top: 3px;">{{ __('Scan to re-open invoice') }}</div>
                    </div>
                </div>

                {{-- 8. Declaration --}}
                <div class="declaration-title">{{ __('Declaration') }}</div>
                <div class="declaration-bar"></div>
                <div class="declaration-text">
                    {{ $settings->invoice_terms_text ?? 'I have read, understood, and accept the terms and conditions mentioned above, the guidelines regarding quality specified at the backside of this invoice, were explained to me. The above jewels mentioned in the invoice are according to my specification and I purchased/sold the jewels at my own wish/need, after due verification. Hereby, indicating the acceptance for above terms & conditions, received the product in good condition, and doing the payment. I further acknowledge the amount stated is correct and accurate.' }}
                </div>

                {{-- 9. Footer --}}
                <div class="invoice-footer">
                    @if(!empty($settings->invoice_company_address))
                        <div>📍 {{ $settings->invoice_company_address }}</div>
                    @endif
                    <div>
                        @if(!empty($settings->invoice_phone_number))
                            📞 {{ $settings->invoice_phone_number }} &nbsp;&nbsp;|&nbsp;&nbsp;
                        @endif
                        @if(!empty($settings->invoice_company_email))
                            ✉ {{ $settings->invoice_company_email }}
                        @endif
                    </div>
                </div>
            </div>

            <div class="actions-bar">
                <button class="btn-print" onclick="window.print()">
                    🖨 {{ __('Print / Download Invoice') }}
                </button>
            </div>
        @else
            {{-- UNVERIFIED / FAKE INVOICE ALERT --}}
            <div class="status-badge fake">
                <div class="status-icon">⚠</div>
                <div>
                    <div class="status-title">{{ __('UNVERIFIED / FAKE INVOICE ALERT') }}</div>
                    <div class="status-desc">
                        {{ __('No matching official invoice could be found for ID / reference:') }} <strong>{{ $id }}</strong>.
                        <br>{{ __('This invoice may have been altered, falsified, or was not generated by our official system.') }}
                    </div>
                </div>
            </div>

            <div class="invoice-card" style="text-align: center; padding: 48px 24px;">
                <div style="font-size: 54px; margin-bottom: 12px;">🚫</div>
                <h2 style="color: #991b1b; font-size: 20px; font-weight: 800; margin-bottom: 8px;">
                    {{ __('Invoice Verification Failed') }}
                </h2>
                <p style="color: #4b5563; font-size: 14px; max-width: 480px; margin: 0 auto 20px auto; line-height: 1.5;">
                    {{ __('The scanned invoice identifier does not match any transaction in our database. If you believe this is an error or have concerns regarding fraud, please contact our support team immediately.') }}
                </p>
                <div style="display: inline-block; background-color: #f9fafb; border: 1px solid #e5e7eb; border-radius: 8px; padding: 12px 20px; font-size: 13px; color: #1f2937;">
                    @if(!empty($settings->invoice_company_email))
                        <div>✉ {{ __('Support Email:') }} <strong>{{ $settings->invoice_company_email }}</strong></div>
                    @endif
                    @if(!empty($settings->invoice_phone_number))
                        <div style="margin-top: 4px;">📞 {{ __('Helpline:') }} <strong>{{ $settings->invoice_phone_number }}</strong></div>
                    @endif
                </div>
            </div>
        @endif
    </div>
</body>
</html>
