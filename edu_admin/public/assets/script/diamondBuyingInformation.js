$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".diamondBuyingInformation").addClass("menuitem-active");

    $("#addDiamondBuyingInformationForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var information = $.trim($("#information").val() || "");
            $("#information").val(information);
            if (!information) {
                showErrorToast("Information is required");
                return;
            }

            var formId = "#addDiamondBuyingInformationForm";
            var url = `${domainUrl}addDiamondBuyingInformation`;
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
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

    $("#editDiamondBuyingInformationForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var information = $.trim($("#edit_information").val() || "");
            $("#edit_information").val(information);
            if (!information) {
                showErrorToast("Information is required");
                return;
            }

            var formId = "#editDiamondBuyingInformationForm";
            var url = `${domainUrl}editDiamondBuyingInformation`;
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
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

    $("#diamond-buying-information-list").on("click", ".delete", function (e) {
        e.preventDefault();
        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                showDenyButton: true,
                denyButtonText: "Cancel",
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    var id = $(this).attr("rel");
                    var url = `${domainUrl}deleteDiamondBuyingInformation`;
                    var formData = new FormData();
                    formData.append("id", id);
                    try {
                        doAjax(url, formData).then(function (response) {
                            if (response.status) {
                                location.reload();
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

    $("#diamond-buying-information-list").on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var information = $(this).data("information");
        $("#editDiamondBuyingInformationId").val(id);
        $("#edit_information").val(information);
        modalShow("#editDiamondBuyingInformationModal");
    });
});

