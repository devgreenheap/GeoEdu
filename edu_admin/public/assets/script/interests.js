$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".interests").addClass("menuitem-active");

    $("#interestsTable").DataTable({
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
            url: `${domainUrl}listInterests`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#addInterestForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#name").val() || "");
            $("#name").val(name);
            if (!name) {
                showErrorToast("Interest name is required");
                return;
            }
            var url = `${domainUrl}addInterest`;
            var formId = '#addInterestForm';
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(['interestsTable']);
                        modalHide('#addInterestModal');
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

    $("#editInterestForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var name = $.trim($("#edit_interest_name").val() || "");
            $("#edit_interest_name").val(name);
            if (!name) {
                showErrorToast("Interest name is required");
                return;
            }
            var url = `${domainUrl}editInterest`;
            var formId = '#editInterestForm';
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(['interestsTable']);
                        modalHide('#editInterestModal');
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

    $("#interestsTable").on("click", ".delete", function (e) {
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
                    var deleteUrl = `${domainUrl}deleteInterest`;
                    var formData = new FormData();
                    formData.append('id', id);
                    try {
                        doAjax(deleteUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(['interestsTable']);
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

    $('#interestsTable').on("change", ".onOffInterest", function () {
        checkUserType(() => {
            const id = $(this).attr("rel");
            const status = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeInterestStatus`,
                data: {
                    id: id,
                    status: status,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        reloadDataTables(['interestsTable']);
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

    $('#interestsTable').on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var name = $(this).data("name");

        $("#editInterestId").val(id);
        $("#edit_interest_name").val(name);

        modalShow('#editInterestModal');
    });

    $("#addInterestModal").on("hidden.bs.modal", function () {
        resetForm('#addInterestForm');
    });

    $("#editInterestModal").on("hidden.bs.modal", function () {
        resetForm('#editInterestForm');
    });
});
