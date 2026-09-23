$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".giftCategories").addClass("menuitem-active");

    $("#addGiftCategoryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var formId = "#addGiftCategoryForm";
            var formdata = collectFormData(formId);
            var name = $.trim($("#addGiftCategoryName").val() || "");
            $("#addGiftCategoryName").val(name);
            if (!name) {
                showErrorToast("Name is required");
                return;
            }
            showFormSpinner(formId);
            try {
                doAjax(`${domainUrl}addGiftCategory`, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                hideFormSpinner(formId);
                showErrorToast(error.message);
            }
        });
    });

    $("#editGiftCategoryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var formId = "#editGiftCategoryForm";
            var formdata = collectFormData(formId);
            var name = $.trim($("#editGiftCategoryName").val() || "");
            $("#editGiftCategoryName").val(name);
            if (!name) {
                showErrorToast("Name is required");
                return;
            }
            showFormSpinner(formId);
            try {
                doAjax(`${domainUrl}editGiftCategory`, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                hideFormSpinner(formId);
                showErrorToast(error.message);
            }
        });
    });

    $("#gift-category-list").on("click", ".delete", function (e) {
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
                    doAjax(`${domainUrl}deleteGiftCategory`, formData).then(function (response) {
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

    $("#gift-category-list").on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var name = $(this).data("name");
        var imageUrl = $(this).data("imageurl");

        $("#editGiftCategoryId").val(id);
        $("#editGiftCategoryName").val(name);
        $("#imgEditGiftCategoryPreview").attr("src", imageUrl);
        modalShow("#editGiftCategoryModal");
    });

    previewImage("#addGiftCategoryImage", "#imgAddGiftCategoryPreview");
    previewImage("#editGiftCategoryImage", "#imgEditGiftCategoryPreview");

    $("#addGiftCategoryModal").on("hidden.bs.modal", function () {
        removeImageSource("#imgAddGiftCategoryPreview");
        resetForm("#addGiftCategoryForm");
    });
    $("#editGiftCategoryModal").on("hidden.bs.modal", function () {
        removeImageSource("#imgEditGiftCategoryPreview");
        resetForm("#editGiftCategoryForm");
    });
});

