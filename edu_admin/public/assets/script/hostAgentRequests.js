$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".hostAgentRequests").addClass("menuitem-active");

    $("#pendingHostAgentRequestsTable").DataTable({
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
            url: `${domainUrl}listPendingHostAgentRequests`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#acceptedHostAgentRequestsTable").DataTable({
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
            url: `${domainUrl}listAcceptedHostAgentRequests`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#rejectedHostAgentRequestsTable").DataTable({
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
            url: `${domainUrl}listRejectedHostAgentRequests`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#pendingHostAgentRequestsTable").on("click", ".accept-role-request", function (e) {
        e.preventDefault();
        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                text: "Do you really want to accept this request?",
                showDenyButton: true,
                denyButtonText: `Cancel`,
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    var itemId = $(this).attr("rel");
                    var actionUrl = `${domainUrl}acceptHostAgentRequest`;
                    var formData = new FormData();
                    formData.append("id", itemId);
                    try {
                        doAjax(actionUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables([
                                    "pendingHostAgentRequestsTable",
                                    "acceptedHostAgentRequestsTable",
                                    "rejectedHostAgentRequestsTable",
                                ]);
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

    $("#pendingHostAgentRequestsTable").on("click", ".reject-role-request", function (e) {
        e.preventDefault();
        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                text: "Do you really want to reject this request?",
                showDenyButton: true,
                denyButtonText: `Cancel`,
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    var itemId = $(this).attr("rel");
                    var actionUrl = `${domainUrl}rejectHostAgentRequest`;
                    var formData = new FormData();
                    formData.append("id", itemId);
                    try {
                        doAjax(actionUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables([
                                    "pendingHostAgentRequestsTable",
                                    "acceptedHostAgentRequestsTable",
                                    "rejectedHostAgentRequestsTable",
                                ]);
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
});
