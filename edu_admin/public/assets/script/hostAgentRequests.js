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

    // Interview Video playback modal handling
    window.playInterviewVideo = function (btn) {
        var $btn = $(btn);
        var videoUrl = $btn.attr("data-video-url") || $btn.data("video-url");
        var userName = $btn.attr("data-user-name") || $btn.data("user-name") || "";
        if (!videoUrl) {
            console.error("No video URL provided");
            return;
        }

        var videoElem = document.getElementById("modalInterviewVideo");
        if (videoElem) {
            $("#modalInterviewVideo source").attr("src", videoUrl);
            videoElem.src = videoUrl;
            videoElem.load();
        }
        $("#modalVideoUserInfo").text(userName ? "Candidate: " + userName : "");
        $("#modalVideoDirectLink").attr("href", videoUrl);

        var opened = false;
        if (typeof $ !== "undefined" && typeof $("#videoPlayerModal").modal === "function") {
            try {
                $("#videoPlayerModal").modal("show");
                opened = true;
            } catch (err) {
                console.log("jQuery modal error: ", err);
            }
        }
        if (!opened && typeof bootstrap !== "undefined" && bootstrap.Modal) {
            try {
                var modal = bootstrap.Modal.getInstance(document.getElementById("videoPlayerModal")) ||
                            new bootstrap.Modal(document.getElementById("videoPlayerModal"));
                modal.show();
                opened = true;
            } catch (err) {
                console.log("Bootstrap modal error: ", err);
            }
        }
        if (!opened) {
            window.open(videoUrl, "_blank");
        }

        if (videoElem) {
            try {
                var playPromise = videoElem.play();
                if (playPromise !== undefined) {
                    playPromise.catch(function (e) {
                        console.log("Auto-play waiting for user interaction: ", e);
                    });
                }
            } catch (e) {
                console.log("Video play error: ", e);
            }
        }
    };

    $(document).on("click", ".play-interview-video", function (e) {
        e.preventDefault();
        window.playInterviewVideo(this);
    });

    $("#videoPlayerModal").on("hidden.bs.modal", function () {
        var videoElem = document.getElementById("modalInterviewVideo");
        if (videoElem) {
            videoElem.pause();
            videoElem.currentTime = 0;
            $("#modalInterviewVideo source").attr("src", "");
            videoElem.src = "";
        }
    });
});
