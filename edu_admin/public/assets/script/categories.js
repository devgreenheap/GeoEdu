$(document).ready(function () {
    const currentTab = new URLSearchParams(window.location.search).get("tab");
    const isSubCategoryTab = currentTab === "sub-category";

    $(".side-nav-item").removeClass("menuitem-active");
    if (isSubCategoryTab) {
        $(".subCategories").addClass("menuitem-active");
    } else {
        $(".categories").addClass("menuitem-active");
    }

    $("#categoriesTable").DataTable({
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
            url: `${domainUrl}listCategories`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#subCategoriesTable").DataTable({
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
            url: `${domainUrl}listSubCategories`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#addCategoryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#name").val() || "");
            $("#name").val(name);
            if (!name) {
                showErrorToast("Category name is required");
                return;
            }
            var url = `${domainUrl}addCategory`;
            var formId = '#addCategoryForm';
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(['categoriesTable']);
                        modalHide('#addCategoryModal');
                        resetForm(formId);
                        showSuccessToast(response.message);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log('Error! : ', error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#editCategoryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#edit_category_name").val() || "");
            $("#edit_category_name").val(name);
            if (!name) {
                showErrorToast("Category name is required");
                return;
            }
            var url = `${domainUrl}editCategory`;
            var formId = '#editCategoryForm';
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(['categoriesTable']);
                        modalHide('#editCategoryModal');
                        resetForm(formId);
                        showSuccessToast(response.message);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log('Error! : ', error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#addSubCategoryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#sub_category_name").val() || "");
            $("#sub_category_name").val(name);
            if (!name) {
                showErrorToast("Sub category name is required");
                return;
            }
            var url = `${domainUrl}addSubCategory`;
            var formId = '#addSubCategoryForm';
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(['subCategoriesTable']);
                        modalHide('#addSubCategoryModal');
                        resetForm(formId);
                        showSuccessToast(response.message);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log('Error! : ', error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#editSubCategoryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#edit_sub_category_name").val() || "");
            $("#edit_sub_category_name").val(name);
            if (!name) {
                showErrorToast("Sub category name is required");
                return;
            }
            var url = `${domainUrl}editSubCategory`;
            var formId = '#editSubCategoryForm';
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(['subCategoriesTable']);
                        modalHide('#editSubCategoryModal');
                        resetForm(formId);
                        showSuccessToast(response.message);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log('Error! : ', error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#categoriesTable").on("click", ".delete", function (e) {
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
                    var id = $(this).attr("rel");
                    var deleteUrl = `${domainUrl}deleteCategory`;
                    var formData = new FormData();
                    formData.append('id', id);
                    try {
                        doAjax(deleteUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(['categoriesTable']);
                                showSuccessToast(response.message);
                            } else {
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
    });

    $("#subCategoriesTable").on("click", ".delete-sub", function (e) {
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
                    var id = $(this).attr("rel");
                    var deleteUrl = `${domainUrl}deleteSubCategory`;
                    var formData = new FormData();
                    formData.append('id', id);
                    try {
                        doAjax(deleteUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(['subCategoriesTable']);
                                showSuccessToast(response.message);
                            } else {
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
    });

    $('#categoriesTable').on("change", ".onOffCategory", function () {
        checkUserType(() => {
            const id = $(this).attr("rel");
            const status = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeCategoryStatus`,
                data: {
                    id: id,
                    status: status,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        reloadDataTables(['categoriesTable']);
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

    $('#subCategoriesTable').on("change", ".onOffSubCategory", function () {
        checkUserType(() => {
            const id = $(this).attr("rel");
            const status = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeSubCategoryStatus`,
                data: {
                    id: id,
                    status: status,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        reloadDataTables(['subCategoriesTable']);
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

    $('#categoriesTable').on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var name = $(this).data("name");

        $("#editCategoryId").val(id);
        $("#edit_category_name").val(name);

        modalShow('#editCategoryModal');
    });

    $('#subCategoriesTable').on("click", ".edit-sub", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var name = $(this).data("name");
        var categoryId = $(this).data("category");

        $("#editSubCategoryId").val(id);
        $("#edit_sub_category_name").val(name);
        $("#edit_sub_category_category_id").val(categoryId).trigger("change");

        modalShow('#editSubCategoryModal');
    });

    $("#addCategoryModal").on("hidden.bs.modal", function () {
        resetForm('#addCategoryForm');
    });

    $("#editCategoryModal").on("hidden.bs.modal", function () {
        resetForm('#editCategoryForm');
    });

    $("#addSubCategoryModal").on("hidden.bs.modal", function () {
        resetForm('#addSubCategoryForm');
    });

    $("#editSubCategoryModal").on("hidden.bs.modal", function () {
        resetForm('#editSubCategoryForm');
    });
});
