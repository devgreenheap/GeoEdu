$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".supports").addClass("menuitem-active");

    const table = $("#supportsTable").DataTable({
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
            url: `${domainUrl}listSupports`,
            data: function (data) {
                data.status = $("#supportStatusFilter").val();
            },
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#supportStatusFilter").on("change", function () {
        table.ajax.reload();
    });

    $("#supportsTable").on("click", ".reply", function (e) {
        e.preventDefault();
        $("#replySupportId").val($(this).attr("rel"));
        $("#replySupportSubject").val($(this).data("subject"));
        $("#replySupportMessage").val($(this).data("message"));
        $("#replySupportText").val($(this).data("reply"));
        modalShow("#replySupportModal");
    });

    $("#replySupportForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            const replyText = $.trim($("#replySupportText").val() || "");
            $("#replySupportText").val(replyText);
            if (!replyText) {
                showErrorToast("Reply is required");
                return;
            }

            const formId = "#replySupportForm";
            const formData = collectFormData(formId);
            showFormSpinner(formId);

            doAjax(`${domainUrl}replySupport`, formData).then(function (response) {
                hideFormSpinner(formId);
                if (response.status) {
                    modalHide("#replySupportModal");
                    resetForm(formId);
                    table.ajax.reload(null, false);
                    showSuccessToast(response.message);
                    return;
                }
                showErrorToast(response.message);
            }).catch(function (error) {
                hideFormSpinner(formId);
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            });
        });
    });

    $("#supportsTable").on("click", ".close-ticket", function (e) {
        e.preventDefault();
        const id = $(this).attr("rel");

        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Close this ticket?",
                showDenyButton: true,
                denyButtonText: "Cancel",
                confirmButtonText: "Yes",
            }).then((result) => {
                if (!result.isConfirmed) {
                    return;
                }

                const formData = new FormData();
                formData.append("id", id);
                doAjax(`${domainUrl}closeSupport`, formData).then(function (response) {
                    if (response.status) {
                        table.ajax.reload(null, false);
                        showSuccessToast(response.message);
                        return;
                    }
                    showErrorToast(response.message);
                }).catch(function (error) {
                    console.log("Error! : ", error.message);
                    showErrorToast(error.message);
                });
            });
        });
    });

    $("#supportsTable").on("click", ".reopen-ticket", function (e) {
        e.preventDefault();
        const id = $(this).attr("rel");

        checkUserType(() => {
            const formData = new FormData();
            formData.append("id", id);
            doAjax(`${domainUrl}reopenSupport`, formData).then(function (response) {
                if (response.status) {
                    table.ajax.reload(null, false);
                    showSuccessToast(response.message);
                    return;
                }
                showErrorToast(response.message);
            }).catch(function (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            });
        });
    });

    $("#replySupportModal").on("hidden.bs.modal", function () {
        resetForm("#replySupportForm");
        $("#replySupportSubject").val("");
        $("#replySupportMessage").val("");
    });
});
