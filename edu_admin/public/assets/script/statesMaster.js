$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".categoryDetails").addClass("menuitem-active");

    $("#statesMasterTable").DataTable({
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
            url: `${domainUrl}listStatesMaster`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#addStateForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const name = $.trim($("#state_name").val() || "");
            $("#state_name").val(name);
            if (!$("#state_country_id").val()) {
                showErrorToast("Country is required");
                return;
            }
            if (!name) {
                showErrorToast("State name is required");
                return;
            }

            const formId = "#addStateForm";
            showFormSpinner(formId);
            doAjax(`${domainUrl}addStateMaster`, collectFormData(formId)).then(function (response) {
                hideFormSpinner(formId);
                if (response.status) {
                    modalHide("#addStateModal");
                    resetForm(formId);
                    reloadDataTables(["statesMasterTable"]);
                    showSuccessToast(response.message);
                } else {
                    showErrorToast(response.message);
                }
            }).catch(function (error) {
                hideFormSpinner(formId);
                showErrorToast(error.message);
            });
        });
    });

    $("#editStateForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const name = $.trim($("#edit_state_name").val() || "");
            $("#edit_state_name").val(name);
            if (!$("#edit_state_country_id").val()) {
                showErrorToast("Country is required");
                return;
            }
            if (!name) {
                showErrorToast("State name is required");
                return;
            }

            const formId = "#editStateForm";
            showFormSpinner(formId);
            doAjax(`${domainUrl}editStateMaster`, collectFormData(formId)).then(function (response) {
                hideFormSpinner(formId);
                if (response.status) {
                    modalHide("#editStateModal");
                    resetForm(formId);
                    reloadDataTables(["statesMasterTable"]);
                    showSuccessToast(response.message);
                } else {
                    showErrorToast(response.message);
                }
            }).catch(function (error) {
                hideFormSpinner(formId);
                showErrorToast(error.message);
            });
        });
    });

    $("#statesMasterTable").on("click", ".edit-state", function (e) {
        e.preventDefault();
        $("#edit_state_id").val($(this).attr("rel"));
        $("#edit_state_country_id").val($(this).data("country-id")).trigger("change");
        $("#edit_state_name").val($(this).data("name"));
        modalShow("#editStateModal");
    });

    $("#statesMasterTable").on("click", ".delete-state", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const id = $(this).attr("rel");
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                showDenyButton: true,
                denyButtonText: "Cancel",
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    const formData = new FormData();
                    formData.append("id", id);
                    doAjax(`${domainUrl}deleteStateMaster`, formData).then(function (response) {
                        if (response.status) {
                            reloadDataTables(["statesMasterTable"]);
                            showSuccessToast(response.message);
                        } else {
                            showErrorToast(response.message);
                        }
                    }).catch(function (error) {
                        showErrorToast(error.message);
                    });
                }
            });
        });
    });
});
