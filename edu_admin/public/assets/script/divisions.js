$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".categoryDetails").addClass("menuitem-active");

    function setSubCategoryOptions(selector, options, selectedId = null) {
        let html = `<option ${selectedId ? "" : "selected"} disabled>Select Sub Category</option>`;
        options.forEach((item) => {
            const selected = selectedId && Number(selectedId) === Number(item.id) ? "selected" : "";
            html += `<option value="${item.id}" ${selected}>${item.name}</option>`;
        });
        $(selector).html(html).trigger("change");
    }

    function loadSubCategories(categoryId, selector, selectedId = null) {
        if (!categoryId) {
            setSubCategoryOptions(selector, []);
            return;
        }
        const formData = new FormData();
        formData.append("category_id", categoryId);
        doAjax(`${domainUrl}listSubCategoriesByCategory`, formData).then(function (response) {
            if (response.status) {
                setSubCategoryOptions(selector, response.data, selectedId);
            } else {
                setSubCategoryOptions(selector, []);
                showErrorToast(response.message);
            }
        }).catch(function (error) {
            setSubCategoryOptions(selector, []);
            showErrorToast(error.message);
        });
    }

    $("#divisionsTable").DataTable({
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
            url: `${domainUrl}listDivisions`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    // Cascade: category -> sub-category (Add modal)
    $("#division_category_id").on("change", function () {
        loadSubCategories($(this).val(), "#division_sub_category_id");
    });

    // Cascade: category -> sub-category (Edit modal)
    $("#edit_division_category_id").on("change", function () {
        loadSubCategories($(this).val(), "#edit_division_sub_category_id");
    });

    // Add Division form submit
    $("#addDivisionForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#division_name").val() || "");
            $("#division_name").val(name);
            if (!name) {
                showErrorToast("Division name is required");
                return;
            }
            var url = `${domainUrl}addDivision`;
            var formId = "#addDivisionForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["divisionsTable"]);
                        modalHide("#addDivisionModal");
                        resetForm(formId);
                        setSubCategoryOptions("#division_sub_category_id", []);
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

    // Edit Division form submit
    $("#editDivisionForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#edit_division_name").val() || "");
            $("#edit_division_name").val(name);
            if (!name) {
                showErrorToast("Division name is required");
                return;
            }
            var url = `${domainUrl}editDivision`;
            var formId = "#editDivisionForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["divisionsTable"]);
                        modalHide("#editDivisionModal");
                        resetForm(formId);
                        setSubCategoryOptions("#edit_division_sub_category_id", []);
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

    // Delete division
    $("#divisionsTable").on("click", ".delete-division", function (e) {
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
                    var deleteUrl = `${domainUrl}deleteDivision`;
                    var formData = new FormData();
                    formData.append("id", id);
                    try {
                        doAjax(deleteUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(["divisionsTable"]);
                                showSuccessToast(response.message);
                            } else {
                                showErrorToast(response.message);
                            }
                        });
                    } catch (error) {
                        showErrorToast(error.message);
                    }
                }
            });
        });
    });

    // Toggle division status
    $("#divisionsTable").on("change", ".onOffDivision", function () {
        checkUserType(() => {
            const id = $(this).attr("rel");
            const status = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeDivisionStatus`,
                data: { id: id, status: status },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        reloadDataTables(["divisionsTable"]);
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

    // Edit division - open modal
    $("#divisionsTable").on("click", ".edit-division", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var name = $(this).data("name");
        var categoryId = $(this).data("category");
        var subCategoryId = $(this).data("sub-category");

        $("#editDivisionId").val(id);
        $("#edit_division_name").val(name);
        $("#edit_division_category_id").val(categoryId).trigger("change.select2");
        loadSubCategories(categoryId, "#edit_division_sub_category_id", subCategoryId);

        modalShow("#editDivisionModal");
    });

    $("#addDivisionModal").on("hidden.bs.modal", function () {
        resetForm("#addDivisionForm");
        setSubCategoryOptions("#division_sub_category_id", []);
    });

    $("#editDivisionModal").on("hidden.bs.modal", function () {
        resetForm("#editDivisionForm");
        setSubCategoryOptions("#edit_division_sub_category_id", []);
    });

    $("#importDivisionForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var file = $("#division_excel_file")[0].files[0];
            if (!file) {
                showErrorToast("Please select a file to import");
                return;
            }
            var formId = "#importDivisionForm";
            var url = `${domainUrl}importDivisions`;
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            doAjax(url, formdata).then(function (response) {
                hideFormSpinner(formId);
                if (response.status) {
                    reloadDataTables(["divisionsTable"]);
                    modalHide("#importDivisionModal");
                    resetForm(formId);
                    showSuccessToast(response.message);
                } else {
                    showErrorToast(response.message);
                }
            }).catch(function (error) {
                hideFormSpinner(formId);
                showErrorToast(error.responseJSON?.message || error.message || 'Import failed');
            });
        });
    });

    $("#importDivisionModal").on("hidden.bs.modal", function () {
        resetForm("#importDivisionForm");
    });
});

