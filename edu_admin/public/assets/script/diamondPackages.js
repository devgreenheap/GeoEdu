$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".diamondPackages").addClass("menuitem-active");

    $("#diamondPackagesTable").DataTable({
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
            url: `${domainUrl}listDiamondPackages`,
            data: function (data) {},
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

    $("#editDiamondPackageForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var url =  `${domainUrl}editDiamondPackage`;
                var formId = '#editDiamondPackageForm';
                var formdata = collectFormData(formId);
                showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response){
                    hideFormSpinner(formId);
                    if(response.status){
                        reloadDataTables(['diamondPackagesTable']);
                        modalHide('#editPackageModal');
                        resetForm(formId);
                        showSuccessToast(response.message);
                    }else{
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
            console.log('Error! : ', error.message);
                showErrorToast(error.message);
            }
        });
    });
    $("#addDiamondPackageForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var url =  `${domainUrl}addDiamondPackage`;
                var formId = '#addDiamondPackageForm';
                var formdata = collectFormData(formId);
                showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response){
                    hideFormSpinner(formId);
                    if(response.status){
                        reloadDataTables(['diamondPackagesTable']);
                        modalHide('#addPackageModal');
                        resetForm(formId);
                        showSuccessToast(response.message);
                    }else{
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
            console.log('Error! : ', error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#diamondPackagesTable").on("click", ".delete", function (e) {
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
                    var cat_id = $(this).attr("rel");
                    var delete_cat_url =
                        `${domainUrl}deleteDiamondPackage`;
                        var formData = new FormData();
                        formData.append('id', cat_id);
                        try {
                            doAjax(delete_cat_url, formData).then(function (response){
                                if(response.status){
                                    reloadDataTables(['diamondPackagesTable']);
                                    showSuccessToast(response.message);
                                }else{
                                    showErrorToast(response.message);
                                }
                            });
                        } catch (error) {
                        console.log('Error! : ', error.message);
                            showErrorToast(error.message);
                        }
                }
            });
        });
    })

    $('#diamondPackagesTable').on("change", ".onOffDiamondPackage", function () {
          checkUserType(() => {
            const id = $(this).attr("rel");
            const status = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeDiamondPackageStatus`,
                data: {
                    id: id,
                    status: status,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        reloadDataTables(['diamondPackagesTable']);
                    } else {
                        somethingWentWrongToast(response.message);
                    }
                },
                error: function () {
                    alert("An error occurred.");
                },
            });
        });
    });

    $('#diamondPackagesTable').on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var diamondamount = $(this).data("diamondamount");
        var diamondprice = $(this).data("diamondprice");
        var discountedprice = $(this).data("discountedprice");
        var offerentryeffectid = $(this).data("offerentryeffectid");
        var playstoreid = $(this).data("playstoreid");
        var appstoreid = $(this).data("appstoreid");
        var image = $(this).data("image");

        $("#editDiamondPackageId").val(id);
        $("#edit_diamond_amount").val(diamondamount);
        $("#edit_diamond_plan_price").val(diamondprice);
        $("#edit_discounted_price").val(discountedprice);
        $("#edit_playstore_product_id").val(playstoreid);
        $("#edit_appstore_product_id").val(appstoreid);
        $("#edit_offer_entry_effect_id").val(offerentryeffectid || "").trigger("change");
        $("#imgEditDiamondPackPreview").attr('src',image);

        modalShow('#editPackageModal');
    });

    previewImage('#inputAddDiamondPackImage','#imgAddDiamondPackPreview');
    previewImage('#inputEditDiamondPackImage','#imgEditDiamondPackPreview');

    $("#addPackageModal").on("hidden.bs.modal", function () {
        removeImageSource('#imgAddDiamondPackPreview');
        resetForm('#addDiamondPackageForm');
    });
    $("#editPackageModal").on("hidden.bs.modal", function () {
        removeImageSource('#imgEditDiamondPackPreview');
        resetForm('#editDiamondPackageForm');
    });

});
