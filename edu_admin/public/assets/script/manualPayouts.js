$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".manualPayouts").addClass("menuitem-active");

    function initServerTable(selector, url) {
        $(selector).DataTable({
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
                url: `${domainUrl}${url}`,
                data: function () {},
                error: (error) => {
                    console.log(error);
                },
            },
            drawCallback: function () {
                $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
            },
        });
    }

    initServerTable("#manualPayoutsTable", "listManualPayouts");
    initServerTable("#todayPayoutUsersTable", "listTodayRealUsersPayout");
    initServerTable("#manualAgentPayoutsTable", "listManualAgentPayouts");
    initServerTable("#todayAgentCommissionTable", "listTodayAgentCommissionPayout");
    initServerTable("#todayAdminPayoutTable", "listTodayAdminPayout");
    initServerTable("#manualAdminPayoutsTable", "listManualAdminPayouts");
    initServerTable("#todayStateAgentPayoutTable", "listTodayStateAgentPayout");
    initServerTable("#manualStateAgentPayoutsTable", "listManualStateAgentPayouts");
    initServerTable("#todayGifterWalletPayoutTable", "listTodayGifterWalletPayout");
    initServerTable("#manualGifterWalletPayoutsTable", "listManualGifterWalletPayouts");

    $("#manualPayoutForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const transferredAmount = parseFloat($("#transferred_amount").val() || "0");
            const maxAmount = parseFloat($("#max_payout_amount").val() || "0");
            if (transferredAmount <= 0) {
                showErrorToast("Transferred amount must be greater than zero");
                return;
            }
            if (transferredAmount > maxAmount) {
                showErrorToast("Transferred amount exceeds max payout amount");
                return;
            }

            var url = `${domainUrl}addManualPayout`;
            var formId = "#manualPayoutForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        showSuccessToast(response.message);
                        modalHide("#manualPayoutModal");
                        resetForm(formId);
                        reloadDataTables(["manualPayoutsTable", "todayPayoutUsersTable"]);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#manualAdminPayoutForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const transferredAmount = parseFloat($("#admin_transferred_amount").val() || "0");
            const maxAmount = parseFloat($("#admin_max_payout_amount").val() || "0");
            if (transferredAmount <= 0) {
                showErrorToast("Transferred amount must be greater than zero");
                return;
            }
            if (transferredAmount > maxAmount) {
                showErrorToast("Transferred amount exceeds max amount");
                return;
            }

            const formId = "#manualAdminPayoutForm";
            showFormSpinner(formId);
            try {
                doAjax(`${domainUrl}addManualAdminPayout`, collectFormData(formId)).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        showSuccessToast(response.message);
                        modalHide("#manualAdminPayoutModal");
                        resetForm(formId);
                        reloadDataTables(["todayAdminPayoutTable", "manualAdminPayoutsTable"]);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#manualStateAgentPayoutForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const transferredAmount = parseFloat($("#state_agent_transferred_amount").val() || "0");
            const maxAmount = parseFloat($("#state_agent_max_payout_amount").val() || "0");
            if (transferredAmount <= 0) {
                showErrorToast("Transferred amount must be greater than zero");
                return;
            }
            if (transferredAmount > maxAmount) {
                showErrorToast("Transferred amount exceeds max amount");
                return;
            }

            const formId = "#manualStateAgentPayoutForm";
            showFormSpinner(formId);
            try {
                doAjax(`${domainUrl}addManualStateAgentPayout`, collectFormData(formId)).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        showSuccessToast(response.message);
                        modalHide("#manualStateAgentPayoutModal");
                        resetForm(formId);
                        reloadDataTables(["todayStateAgentPayoutTable", "manualStateAgentPayoutsTable"]);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#manualGifterWalletPayoutForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const transferredAmount = parseFloat($("#gifter_wallet_transferred_amount").val() || "0");
            const maxAmount = parseFloat($("#gifter_wallet_max_payout_amount").val() || "0");
            if (transferredAmount <= 0) {
                showErrorToast("Transferred amount must be greater than zero");
                return;
            }
            if (transferredAmount > maxAmount) {
                showErrorToast("Transferred amount exceeds max amount");
                return;
            }

            const formId = "#manualGifterWalletPayoutForm";
            showFormSpinner(formId);
            try {
                doAjax(`${domainUrl}addManualGifterWalletPayout`, collectFormData(formId)).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        showSuccessToast(response.message);
                        modalHide("#manualGifterWalletPayoutModal");
                        resetForm(formId);
                        reloadDataTables(["todayGifterWalletPayoutTable", "manualGifterWalletPayoutsTable"]);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#manualAgentPayoutForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const transferredAmount = parseFloat($("#agent_transferred_amount").val() || "0");
            const maxAmount = parseFloat($("#agent_max_payout_amount").val() || "0");
            if (transferredAmount <= 0) {
                showErrorToast("Transferred amount must be greater than zero");
                return;
            }
            if (transferredAmount > maxAmount) {
                showErrorToast("Transferred amount exceeds max amount");
                return;
            }

            var url = `${domainUrl}addManualAgentPayout`;
            var formId = "#manualAgentPayoutForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        showSuccessToast(response.message);
                        modalHide("#manualAgentPayoutModal");
                        resetForm(formId);
                        reloadDataTables(["manualAgentPayoutsTable", "todayAgentCommissionTable"]);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            }
        });
    });

    function updatePayoutPreview() {
        const transferredAmount = parseFloat($("#transferred_amount").val() || "0");
        const payoutAmount = Math.max(0, transferredAmount);
        $("#payout_amount_display").val(payoutAmount.toFixed(2));
    }

    $("#transferred_amount").on("input", function () {
        updatePayoutPreview();
    });

    $("#todayPayoutUsersTable").on("click", ".use-for-payout", function (e) {
        e.preventDefault();
        const userId = $(this).data("user-id");
        const stars = $(this).data("stars");
        const maxAmount = parseFloat($(this).data("max-amount") || "0");
        $("#user_id").val(userId);
        $("#available_stars_display").val(stars);
        $("#max_payout_amount").val(maxAmount.toFixed(2));
        $("#max_payout_amount_display").val(maxAmount.toFixed(2));
        const now = new Date();
        const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        $("#paid_date").val(localIso);
        $("#transferred_amount").val("");
        $("#payout_amount_display").val("0.00");
        $("#description").val("");
        $("#transaction_id").val("");
        modalShow("#manualPayoutModal");
        $("#transferred_amount").focus();
    });

    $("#todayAgentCommissionTable").on("click", ".use-for-agent-payout", function (e) {
        e.preventDefault();
        const agentId = $(this).data("agent-id");
        const wallet = parseFloat($(this).data("wallet") || "0");
        $("#agent_id").val(agentId);
        $("#agent_wallet_display").val(wallet.toFixed(2));
        $("#agent_max_payout_amount").val(wallet.toFixed(2));
        $("#agent_max_payout_amount_display").val(wallet.toFixed(2));
        const now = new Date();
        const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        $("#agent_paid_date").val(localIso);
        $("#agent_transferred_amount").val("");
        $("#agent_description").val("");
        $("#agent_transaction_id").val("");
        modalShow("#manualAgentPayoutModal");
        $("#agent_transferred_amount").focus();
    });

    $("#todayAdminPayoutTable").on("click", ".use-for-admin-payout", function (e) {
        e.preventDefault();
        const wallet = parseFloat($(this).data("wallet") || "0");
        $("#admin_wallet_display").val(wallet.toFixed(2));
        $("#admin_max_payout_amount").val(wallet.toFixed(2));
        $("#admin_max_payout_amount_display").val(wallet.toFixed(2));
        const now = new Date();
        const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        $("#admin_paid_date").val(localIso);
        $("#admin_transferred_amount").val("");
        $("#admin_description").val("");
        $("#admin_transaction_id").val("");
        modalShow("#manualAdminPayoutModal");
        $("#admin_transferred_amount").focus();
    });

    $("#todayStateAgentPayoutTable").on("click", ".use-for-state-agent-payout", function (e) {
        e.preventDefault();
        const userId = $(this).data("user-id");
        const stars = parseInt($(this).data("stars") || "0", 10);
        const maxAmount = parseFloat($(this).data("max-amount") || "0");
        $("#state_agent_user_id").val(userId);
        $("#state_agent_stars_display").val(stars);
        $("#state_agent_max_payout_amount").val(maxAmount.toFixed(2));
        $("#state_agent_max_payout_amount_display").val(maxAmount.toFixed(2));
        const now = new Date();
        const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        $("#state_agent_paid_date").val(localIso);
        $("#state_agent_transferred_amount").val("");
        $("#state_agent_description").val("");
        $("#state_agent_transaction_id").val("");
        modalShow("#manualStateAgentPayoutModal");
        $("#state_agent_transferred_amount").focus();
    });

    $("#todayGifterWalletPayoutTable").on("click", ".use-for-gifter-wallet-payout", function (e) {
        e.preventDefault();
        const userId = $(this).data("user-id");
        const categoryId = parseInt($(this).data("category-id") || "0", 10);
        const categoryName = ($(this).data("category-name") || "General").toString();
        const stars = parseInt($(this).data("stars") || "0", 10);
        const maxAmount = parseFloat($(this).data("max-amount") || "0");
        $("#gifter_wallet_user_id").val(userId);
        $("#gifter_wallet_category_id").val(categoryId);
        $("#gifter_wallet_category_display").val(categoryName);
        $("#gifter_wallet_stars_display").val(stars);
        $("#gifter_wallet_max_payout_amount").val(maxAmount.toFixed(2));
        $("#gifter_wallet_max_payout_amount_display").val(maxAmount.toFixed(2));
        const now = new Date();
        const localIso = new Date(now.getTime() - now.getTimezoneOffset() * 60000).toISOString().slice(0, 16);
        $("#gifter_wallet_paid_date").val(localIso);
        $("#gifter_wallet_transferred_amount").val("");
        $("#gifter_wallet_description").val("");
        $("#gifter_wallet_transaction_id").val("");
        modalShow("#manualGifterWalletPayoutModal");
        $("#gifter_wallet_transferred_amount").focus();
    });
});
