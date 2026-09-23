$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".banners").addClass("menuitem-active");

    $("#addBannerForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var formId = "#addBannerForm";
            var formData = collectFormData(formId);
            var type = $.trim($("#addBannerType").val() || "").toLowerCase();
            $("#addBannerType").val(type);
            if (type !== "audio" && type !== "homepage") {
                showErrorToast("Type must be audio or homepage");
                return;
            }

            showFormSpinner(formId);
            doAjax(`${domainUrl}addBanner`, formData)
                .then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
                    } else {
                        showErrorToast(response.message);
                    }
                })
                .catch(function (error) {
                    hideFormSpinner(formId);
                    showErrorToast(error.message);
                });
        });
    });

    $("#editBannerForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var formId = "#editBannerForm";
            var formData = collectFormData(formId);
            var type = $.trim($("#editBannerType").val() || "").toLowerCase();
            $("#editBannerType").val(type);
            if (type !== "audio" && type !== "homepage") {
                showErrorToast("Type must be audio or homepage");
                return;
            }

            showFormSpinner(formId);
            doAjax(`${domainUrl}editBanner`, formData)
                .then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
                    } else {
                        showErrorToast(response.message);
                    }
                })
                .catch(function (error) {
                    hideFormSpinner(formId);
                    showErrorToast(error.message);
                });
        });
    });

    $("#banner-list").on("click", ".delete", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");

        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                showDenyButton: true,
                denyButtonText: "Cancel",
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    var formData = new FormData();
                    formData.append("id", id);
                    doAjax(`${domainUrl}deleteBanner`, formData).then(function (response) {
                        if (response.status) {
                            location.reload();
                        } else {
                            showErrorToast(response.message);
                        }
                    });
                }
            });
        });
    });

    $("#banner-list").on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var type = ($(this).data("type") || "").toString().toLowerCase();
        var imageUrl = $(this).data("imageurl");

        $("#editBannerId").val(id);
        $("#editBannerType").val(type);
        $("#imgEditBannerPreview").attr("src", imageUrl);
        modalShow("#editBannerModal");
    });

    previewImage("#addBannerImage", "#imgAddBannerPreview");
    previewImage("#editBannerImage", "#imgEditBannerPreview");

    $("#addBannerModal").on("hidden.bs.modal", function () {
        removeImageSource("#imgAddBannerPreview");
        resetForm("#addBannerForm");
    });

    $("#editBannerModal").on("hidden.bs.modal", function () {
        removeImageSource("#imgEditBannerPreview");
        resetForm("#editBannerForm");
    });
});
