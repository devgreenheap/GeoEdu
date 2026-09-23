$(document).ready(function () {
    let currentStatus = 0;

    const table = $("#screenshotDisableRequestsTable").DataTable({
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
            url: `${domainUrl}listScreenshotDisableRequests`,
            data: function (d) {
                d.status = currentStatus;
            },
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $(".screenshot-disable-tab-link").on("click", function (e) {
        e.preventDefault();
        $(".screenshot-disable-tab-link").removeClass("active show");
        $(this).addClass("active show");
        currentStatus = parseInt($(this).data("status"), 10) || 0;
        table.ajax.reload(null, true);
    });

    $("#screenshotDisableRequestsTable").on("click", ".approve-screenshot-disable", function (e) {
        e.preventDefault();
        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                text: "Do you want to approve this request?",
                showDenyButton: true,
                denyButtonText: "Cancel",
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    const requestId = $(this).attr("rel");
                    const formData = new FormData();
                    formData.append("id", requestId);
                    doAjax(`${domainUrl}approveScreenshotDisableRequest`, formData)
                        .then(function (response) {
                            if (response.status) {
                                table.ajax.reload(null, false);
                                showSuccessToast(response.message);
                            } else {
                                showErrorToast(response.message);
                            }
                        })
                        .catch(function (error) {
                            showErrorToast(error.message);
                        });
                }
            });
        });
    });
});
