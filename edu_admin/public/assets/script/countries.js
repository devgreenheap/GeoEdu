$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".categoryDetails").addClass("menuitem-active");

    $("#countriesTable").DataTable({
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
            url: `${domainUrl}listCountries`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#addCountryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const name = $.trim($("#country_name").val() || "");
            $("#country_name").val(name);
            if (!name) {
                showErrorToast("Country name is required");
                return;
            }

            const formId = "#addCountryForm";
            showFormSpinner(formId);
            doAjax(`${domainUrl}addCountry`, collectFormData(formId)).then(function (response) {
                hideFormSpinner(formId);
                if (response.status) {
                    modalHide("#addCountryModal");
                    resetForm(formId);
                    reloadDataTables(["countriesTable"]);
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

    $("#editCountryForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const name = $.trim($("#edit_country_name").val() || "");
            $("#edit_country_name").val(name);
            if (!name) {
                showErrorToast("Country name is required");
                return;
            }

            const formId = "#editCountryForm";
            showFormSpinner(formId);
            doAjax(`${domainUrl}editCountry`, collectFormData(formId)).then(function (response) {
                hideFormSpinner(formId);
                if (response.status) {
                    modalHide("#editCountryModal");
                    resetForm(formId);
                    reloadDataTables(["countriesTable"]);
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

    $("#countriesTable").on("click", ".edit-country", function (e) {
        e.preventDefault();
        $("#edit_country_id").val($(this).attr("rel"));
        $("#edit_country_name").val($(this).data("name"));
        modalShow("#editCountryModal");
    });

    $("#countriesTable").on("click", ".delete-country", function (e) {
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
                    doAjax(`${domainUrl}deleteCountry`, formData).then(function (response) {
                        if (response.status) {
                            reloadDataTables(["countriesTable"]);
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
