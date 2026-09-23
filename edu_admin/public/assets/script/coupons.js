$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".coupons").addClass("menuitem-active");

    function toggleAddEndDate() {
        const isUnlimited = $("#add_unlimited_end_date").is(":checked");
        $("#end_date").prop("disabled", isUnlimited);
        if (isUnlimited) {
            $("#end_date").val("");
        }
    }

    function toggleAddUsers() {
        const isUnlimited = $("#add_unlimited_users").is(":checked");
        $("#max_users").prop("disabled", isUnlimited);
        if (isUnlimited) {
            $("#max_users").val("");
        }
    }

    function toggleEditEndDate() {
        const isUnlimited = $("#edit_unlimited_end_date").is(":checked");
        $("#edit_end_date").prop("disabled", isUnlimited);
        if (isUnlimited) {
            $("#edit_end_date").val("");
        }
    }

    function toggleEditUsers() {
        const isUnlimited = $("#edit_unlimited_users").is(":checked");
        $("#edit_max_users").prop("disabled", isUnlimited);
        if (isUnlimited) {
            $("#edit_max_users").val("");
        }
    }

    $("#add_unlimited_end_date").on("change", toggleAddEndDate);
    $("#add_unlimited_users").on("change", toggleAddUsers);
    $("#edit_unlimited_end_date").on("change", toggleEditEndDate);
    $("#edit_unlimited_users").on("change", toggleEditUsers);

    $("#couponsTable").DataTable({
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
            url: `${domainUrl}listCoupons`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass(
                "pagination-rounded"
            );
        },
    });

    $("#addCouponForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}addCoupon`;
            var formId = "#addCouponForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["couponsTable"]);
                        modalHide("#addCouponModal");
                        resetForm(formId);
                        toggleAddEndDate();
                        toggleAddUsers();
                        showSuccessToast(response.message);
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

    $("#editCouponForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}editCoupon`;
            var formId = "#editCouponForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["couponsTable"]);
                        modalHide("#editCouponModal");
                        resetForm(formId);
                        showSuccessToast(response.message);
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

    $("#couponsTable").on("click", ".delete", function (e) {
        e.preventDefault();
        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                showDenyButton: true,
                denyButtonText: `Cancel`,
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    var itemId = $(this).attr("rel");
                    var actionUrl = `${domainUrl}deleteCoupon`;
                    var formData = new FormData();
                    formData.append("id", itemId);
                    try {
                        doAjax(actionUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(["couponsTable"]);
                                showSuccessToast(response.message);
                            } else {
                                showErrorToast(response.message);
                            }
                        });
                    } catch (error) {
                        console.log("Error! : ", error.message);
                        showErrorToast(error.message);
                    }
                }
            });
        });
    });

    $("#couponsTable").on("change", ".onOffCoupon", function () {
        checkUserType(() => {
            const id = $(this).attr("rel");
            const status = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeCouponStatus`,
                data: {
                    id: id,
                    status: status,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        reloadDataTables(["couponsTable"]);
                    } else {
                        showErrorToast(response.message);
                    }
                },
                error: function () {
                    alert("An error occurred.");
                },
            });
        });
    });

    $("#couponsTable").on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var couponCode = $(this).data("couponcode");
        var discountType = $(this).data("discounttype");
        var discountValue = $(this).data("discountvalue");
        var endDate = $(this).data("enddate");
        var maxUsers = $(this).data("maxusers");

        $("#editCouponId").val(id);
        $("#edit_coupon_code").val(couponCode);
        $("#edit_discount_type").val(discountType);
        $("#edit_discount_value").val(discountValue);
        $("#edit_end_date").val(endDate || "");
        $("#edit_max_users").val(maxUsers || "");
        $("#edit_unlimited_end_date").prop("checked", !endDate);
        $("#edit_unlimited_users").prop("checked", !maxUsers);
        toggleEditEndDate();
        toggleEditUsers();
        modalShow("#editCouponModal");
    });

    $("#addCouponModal").on("hidden.bs.modal", function () {
        resetForm("#addCouponForm");
        toggleAddEndDate();
        toggleAddUsers();
    });

    toggleAddEndDate();
    toggleAddUsers();
});
