$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".topics").addClass("menuitem-active");

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
            console.log("Error! : ", error.message);
            setSubCategoryOptions(selector, []);
            showErrorToast(error.message);
        });
    }

    $("#topicsTable").DataTable({
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
            url: `${domainUrl}listTopics`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#topic_category_id").on("change", function () {
        loadSubCategories($(this).val(), "#topic_sub_category_id");
    });

    $("#edit_topic_category_id").on("change", function () {
        loadSubCategories($(this).val(), "#edit_topic_sub_category_id");
    });

    $("#addTopicForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}addTopic`;
            var formId = "#addTopicForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["topicsTable"]);
                        modalHide("#addTopicModal");
                        resetForm(formId);
                        setSubCategoryOptions("#topic_sub_category_id", []);
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

    $("#editTopicForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}editTopic`;
            var formId = "#editTopicForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["topicsTable"]);
                        modalHide("#editTopicModal");
                        resetForm(formId);
                        setSubCategoryOptions("#edit_topic_sub_category_id", []);
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

    $("#topicsTable").on("click", ".delete", function (e) {
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
                    var deleteUrl = `${domainUrl}deleteTopic`;
                    var formData = new FormData();
                    formData.append("id", id);
                    try {
                        doAjax(deleteUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(["topicsTable"]);
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

    $("#topicsTable").on("change", ".onOffTopic", function () {
        checkUserType(() => {
            const id = $(this).attr("rel");
            const status = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeTopicStatus`,
                data: {
                    id: id,
                    status: status,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        reloadDataTables(["topicsTable"]);
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

    $("#topicsTable").on("click", ".edit", function (e) {
        e.preventDefault();

        var id = $(this).attr("rel");
        var name = $(this).data("name");
        var categoryId = $(this).data("category");
        var subCategoryId = $(this).data("sub-category");

        $("#editTopicId").val(id);
        $("#edit_topic_name").val(name);
        $("#edit_topic_category_id").val(categoryId).trigger("change.select2");
        loadSubCategories(categoryId, "#edit_topic_sub_category_id", subCategoryId);

        modalShow("#editTopicModal");
    });

    $("#addTopicModal").on("hidden.bs.modal", function () {
        resetForm("#addTopicForm");
        setSubCategoryOptions("#topic_sub_category_id", []);
    });

    $("#editTopicModal").on("hidden.bs.modal", function () {
        resetForm("#editTopicForm");
        setSubCategoryOptions("#edit_topic_sub_category_id", []);
    });
});
