$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".requestedPayouts").addClass("menuitem-active");

    const tableSelector = "#requestedPayoutsTable";

    const table = $(tableSelector).DataTable({
        autoWidth: false,
        processing: true,
        serverSide: true,
        serverMethod: "post",
        ordering: false,
        language: {
            paginate: {
                previous: "<i class='mdi mdi-chevron-left'>",
                next: "<i class='mdi mdi-chevron-right'>",
            },
        },
        ajax: {
            url: `${domainUrl}listRequestedPayouts`,
            data: function (d) {
                d.status_filter = $("#statusFilter").val();
            },
            error: function (error) {
                console.error("Requested Payouts Table Error:", error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#statusFilter").on("change", function () {
        table.ajax.reload();
    });

    $("#refreshBtn").on("click", function () {
        table.ajax.reload();
    });

    // Helper: format today's date YYYY-MM-DD
    function getTodayDateString() {
        const today = new Date();
        const year = today.getFullYear();
        const month = String(today.getMonth() + 1).padStart(2, "0");
        const day = String(today.getDate()).padStart(2, "0");
        return `${year}-${month}-${day}`;
    }

    // Helper: format current time HH:MM
    function getCurrentTimeString() {
        const now = new Date();
        const hours = String(now.getHours()).padStart(2, "0");
        const minutes = String(now.getMinutes()).padStart(2, "0");
        return `${hours}:${minutes}`;
    }

    // Approve Button Click -> Open Payment Confirmation Modal
    $(document).on("click", ".approve-request-btn", function () {
        const payoutId = $(this).data("id");
        if (!payoutId) return;

        // Fetch details to populate modal
        $.ajax({
            url: `${domainUrl}getRequestedPayoutDetails`,
            type: "POST",
            data: { id: payoutId },
            success: function (res) {
                if (res.status && res.data) {
                    const data = res.data;
                    $("#approve_payout_id").val(data.id);
                    $("#approve_host_name").text(data.host_name);
                    $("#approve_host_info").text(`User ID: ${data.user_id} | Identity: ${data.host_identity || '-'}`);
                    $("#approve_req_amount").text(`${data.currency} ${parseFloat(data.requested_amount).toFixed(2)}`);
                    $("#approve_req_stars").html(`<i class="uil-star text-warning"></i> ${data.requested_stars} Stars (Category: ${data.category_name})`);

                    let targetHtml = "";
                    if (data.payout_method === "GPay/UPI" || data.upi_id !== "-" || data.upi_number !== "-") {
                        targetHtml += `<div class="d-flex align-items-center mb-1"><span class="badge bg-success me-2">GPay / UPI</span> <span>Destination Details:</span></div>`;
                        if (data.upi_id && data.upi_id !== "-") {
                            targetHtml += `<div><strong>UPI ID:</strong> <span class="text-primary fw-bold">${data.upi_id}</span></div>`;
                        }
                        if (data.upi_number && data.upi_number !== "-") {
                            targetHtml += `<div><strong>GPay/UPI No:</strong> ${data.upi_number}</div>`;
                        }
                        if (data.phone_number && data.phone_number !== "-") {
                            targetHtml += `<div><strong>Phone:</strong> ${data.phone_number}</div>`;
                        }
                    } else {
                        targetHtml += `<div class="d-flex align-items-center mb-1"><span class="badge bg-primary me-2">Bank Transfer</span> <span>Bank Account Details:</span></div>`;
                        targetHtml += `<div><strong>Account Holder:</strong> ${data.account_holder_name}</div>`;
                        targetHtml += `<div><strong>Account Number:</strong> <span class="text-primary fw-bold">${data.account_number}</span></div>`;
                        targetHtml += `<div><strong>IFSC Code:</strong> ${data.ifsc_code}</div>`;
                        if (data.phone_number && data.phone_number !== "-") {
                            targetHtml += `<div><strong>Phone:</strong> ${data.phone_number}</div>`;
                        }
                    }
                    $("#approve_payout_target_details").html(targetHtml);

                    // Prefill payment form fields
                    $("#approve_transaction_id").val("");
                    $("#approve_paid_amount").val(data.requested_amount);
                    $("#approve_payment_date").val(getTodayDateString());
                    $("#approve_payment_time").val(getCurrentTimeString());
                    $("#approve_admin_note").val("");

                    $("#approvePayoutModal").modal("show");
                } else {
                    showErrorToast(res.message || "Failed to load payout details.");
                }
            },
            error: function (err) {
                console.error(err);
                showErrorToast("Error retrieving payout information.");
            },
        });
    });

    // Approve Form Submit -> Confirms Payment and Marks Approved
    $("#approvePayoutForm").on("submit", function (e) {
        e.preventDefault();

        const form = $(this);
        const txnId = $("#approve_transaction_id").val().trim();
        const paidAmount = parseFloat($("#approve_paid_amount").val() || "0");
        const payDate = $("#approve_payment_date").val();
        const payTime = $("#approve_payment_time").val();

        if (!txnId) {
            showErrorToast("Transaction ID is mandatory.");
            $("#approve_transaction_id").focus();
            return;
        }

        if (isNaN(paidAmount) || paidAmount <= 0) {
            showErrorToast("Please enter a valid paid amount greater than zero.");
            $("#approve_paid_amount").focus();
            return;
        }

        if (!payDate) {
            showErrorToast("Payment Date is mandatory.");
            $("#approve_payment_date").focus();
            return;
        }

        if (!payTime) {
            showErrorToast("Payment Time is mandatory.");
            $("#approve_payment_time").focus();
            return;
        }

        const submitBtn = $("#confirmApproveBtn");
        submitBtn.prop("disabled", true);
        submitBtn.find(".spinner-border").removeClass("hide");

        $.ajax({
            url: `${domainUrl}approveRequestedPayout`,
            type: "POST",
            data: form.serialize(),
            success: function (res) {
                submitBtn.prop("disabled", false);
                submitBtn.find(".spinner-border").addClass("hide");

                if (res.status) {
                    showSuccessToast(res.message || "Payment confirmed and payout approved!");
                    $("#approvePayoutModal").modal("hide");
                    table.ajax.reload();
                    location.reload(); // Refresh stats cards
                } else {
                    showErrorToast(res.message || "Failed to confirm payment.");
                }
            },
            error: function (err) {
                submitBtn.prop("disabled", false);
                submitBtn.find(".spinner-border").addClass("hide");
                console.error(err);
                showErrorToast("An error occurred while approving payout.");
            },
        });
    });

    // Reject Button Click -> Open Reject Modal
    $(document).on("click", ".reject-request-btn", function () {
        const payoutId = $(this).data("id");
        if (!payoutId) return;

        $("#reject_payout_id").val(payoutId);
        $("#reject_admin_note").val("");
        $("#rejectPayoutModal").modal("show");
    });

    // Reject Form Submit
    $("#rejectPayoutForm").on("submit", function (e) {
        e.preventDefault();

        const form = $(this);
        const note = $("#reject_admin_note").val().trim();
        if (!note) {
            showErrorToast("Please enter a rejection reason.");
            $("#reject_admin_note").focus();
            return;
        }

        const submitBtn = $("#confirmRejectBtn");
        submitBtn.prop("disabled", true);
        submitBtn.find(".spinner-border").removeClass("hide");

        $.ajax({
            url: `${domainUrl}rejectRequestedPayout`,
            type: "POST",
            data: form.serialize(),
            success: function (res) {
                submitBtn.prop("disabled", false);
                submitBtn.find(".spinner-border").addClass("hide");

                if (res.status) {
                    showSuccessToast(res.message || "Payout rejected and stars refunded.");
                    $("#rejectPayoutModal").modal("hide");
                    table.ajax.reload();
                    location.reload(); // Refresh stats cards
                } else {
                    showErrorToast(res.message || "Failed to reject payout.");
                }
            },
            error: function (err) {
                submitBtn.prop("disabled", false);
                submitBtn.find(".spinner-border").addClass("hide");
                console.error(err);
                showErrorToast("An error occurred while rejecting payout.");
            },
        });
    });

    // View Button Click -> Open Details Modal
    $(document).on("click", ".view-request-btn", function () {
        const payoutId = $(this).data("id");
        if (!payoutId) return;

        $("#viewPayoutBody").html(`
            <div class="text-center py-4">
                <div class="spinner-border text-primary" role="status"></div>
                <div class="text-muted small mt-2">Loading details...</div>
            </div>
        `);
        $("#viewPayoutModal").modal("show");

        $.ajax({
            url: `${domainUrl}getRequestedPayoutDetails`,
            type: "POST",
            data: { id: payoutId },
            success: function (res) {
                if (res.status && res.data) {
                    const d = res.data;
                    let statusBadgeClass = "bg-warning text-dark";
                    if (d.status === 1) statusBadgeClass = "bg-success text-white";
                    if (d.status === 2) statusBadgeClass = "bg-danger text-white";

                    let paymentHtml = "";
                    if (d.status === 1) {
                        paymentHtml = `
                            <div class="card bg-success-lighten border-success mt-3 mb-0">
                                <div class="card-body p-3">
                                    <h5 class="text-success mb-2"><i class="uil-check-circle me-1"></i> Admin Payment Confirmation</h5>
                                    <div class="row g-2">
                                        <div class="col-sm-6"><strong>Transaction ID:</strong> <span class="text-primary fw-bold">${d.transaction_id || '-'}</span></div>
                                        <div class="col-sm-6"><strong>Amount Paid:</strong> ${d.currency} ${parseFloat(d.paid_amount || d.requested_amount).toFixed(2)}</div>
                                        <div class="col-sm-6"><strong>Payment Date:</strong> ${d.payment_date || '-'}</div>
                                        <div class="col-sm-6"><strong>Payment Time:</strong> ${d.payment_time || '-'}</div>
                                        ${d.admin_note ? `<div class="col-12 mt-1"><strong>Admin Note:</strong> ${d.admin_note}</div>` : ''}
                                    </div>
                                </div>
                            </div>
                        `;
                    } else if (d.status === 2 && d.admin_note) {
                        paymentHtml = `
                            <div class="alert alert-danger mt-3 mb-0">
                                <strong>Rejection Reason:</strong> ${d.admin_note}
                            </div>
                        `;
                    }

                    let destinationHtml = "";
                    if (d.payout_method === "GPay/UPI" || d.upi_id !== "-" || d.upi_number !== "-") {
                        destinationHtml = `
                            <p class="mb-1"><strong>Method:</strong> <span class="badge bg-success">GPay / UPI</span></p>
                            <p class="mb-1"><strong>UPI ID:</strong> <span class="text-primary fw-bold">${d.upi_id}</span></p>
                            <p class="mb-1"><strong>GPay Number:</strong> ${d.upi_number}</p>
                            <p class="mb-0"><strong>Phone:</strong> ${d.phone_number}</p>
                        `;
                    } else {
                        destinationHtml = `
                            <p class="mb-1"><strong>Method:</strong> <span class="badge bg-primary">Bank Transfer</span></p>
                            <p class="mb-1"><strong>Account Holder:</strong> ${d.account_holder_name}</p>
                            <p class="mb-1"><strong>Account Number:</strong> <span class="text-primary fw-bold">${d.account_number}</span></p>
                            <p class="mb-1"><strong>IFSC Code:</strong> ${d.ifsc_code}</p>
                            <p class="mb-0"><strong>Phone:</strong> ${d.phone_number}</p>
                        `;
                    }

                    const html = `
                        <div class="row g-3">
                            <div class="col-md-6">
                                <div class="p-3 bg-light rounded border h-100">
                                    <h5 class="mb-2 text-dark"><i class="uil-user me-1"></i> Host Information</h5>
                                    <p class="mb-1"><strong>Host Name:</strong> ${d.host_name}</p>
                                    <p class="mb-1"><strong>User ID:</strong> ${d.user_id}</p>
                                    <p class="mb-1"><strong>Identity:</strong> ${d.host_identity || '-'}</p>
                                    <p class="mb-0"><strong>Current Stars in Wallet:</strong> <span class="badge bg-warning text-dark">${d.available_stars}</span></p>
                                </div>
                            </div>
                            <div class="col-md-6">
                                <div class="p-3 bg-light rounded border h-100">
                                    <h5 class="mb-2 text-dark"><i class="uil-file-alt me-1"></i> Request Summary</h5>
                                    <p class="mb-1"><strong>Request ID:</strong> #${d.id} (${d.request_number || '-'})</p>
                                    <p class="mb-1"><strong>Category:</strong> <span class="badge bg-secondary">${d.category_name}</span></p>
                                    <p class="mb-1"><strong>Stars Requested:</strong> ${d.requested_stars} Stars</p>
                                    <p class="mb-1"><strong>Amount Requested:</strong> <span class="text-primary fw-bold">${d.currency} ${parseFloat(d.requested_amount).toFixed(2)}</span></p>
                                    <p class="mb-1"><strong>Request Date:</strong> ${d.created_at}</p>
                                    <p class="mb-0"><strong>Status:</strong> <span class="badge ${statusBadgeClass}">${d.status_text}</span></p>
                                </div>
                            </div>
                            <div class="col-12">
                                <div class="p-3 bg-light rounded border">
                                    <h5 class="mb-2 text-dark"><i class="uil-wallet me-1"></i> Destination Payout Account</h5>
                                    ${destinationHtml}
                                </div>
                            </div>
                        </div>
                        ${paymentHtml}
                    `;

                    $("#viewPayoutBody").html(html);
                } else {
                    $("#viewPayoutBody").html(`<div class="alert alert-danger">${res.message || 'Failed to load details.'}</div>`);
                }
            },
            error: function () {
                $("#viewPayoutBody").html(`<div class="alert alert-danger">Error retrieving details from server.</div>`);
            },
        });
    });
});
