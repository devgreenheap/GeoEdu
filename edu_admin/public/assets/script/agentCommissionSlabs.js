$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".agentCommissionSlabs").addClass("menuitem-active");

    $("#agentCommissionSlabsTable").DataTable({
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
            url: `${domainUrl}listAgentCommissionSlabs`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#addAgentCommissionSlabForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}addAgentCommissionSlab`;
            var formId = "#addAgentCommissionSlabForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["agentCommissionSlabsTable"]);
                        modalHide("#addAgentCommissionSlabModal");
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

    $("#editAgentCommissionSlabForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}editAgentCommissionSlab`;
            var formId = "#editAgentCommissionSlabForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["agentCommissionSlabsTable"]);
                        modalHide("#editAgentCommissionSlabModal");
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

    $("#agentCommissionSlabsTable").on("click", ".edit", function (e) {
        e.preventDefault();
        $("#editAgentCommissionSlabId").val($(this).attr("rel"));
        $("#edit_start_level").val($(this).data("startlevel"));
        $("#edit_end_level").val($(this).data("endlevel"));
        $("#edit_commission_percent").val($(this).data("commissionpercent"));
        modalShow("#editAgentCommissionSlabModal");
    });

    $("#agentCommissionSlabsTable").on("click", ".delete", function (e) {
        e.preventDefault();
        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                showDenyButton: true,
                denyButtonText: "Cancel",
                confirmButtonText: "Yes",
            }).then((result) => {
                if (!result.isConfirmed) {
                    return;
                }
                var itemId = $(this).attr("rel");
                var formData = new FormData();
                formData.append("id", itemId);
                try {
                    doAjax(`${domainUrl}deleteAgentCommissionSlab`, formData).then(function (response) {
                        if (response.status) {
                            reloadDataTables(["agentCommissionSlabsTable"]);
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
    });
});

