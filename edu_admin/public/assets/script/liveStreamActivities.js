$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".liveStreams").addClass("menuitem-active");

    const streamIdFromInput = ($("#live_stream_id").val() || "").toString().trim();
    const streamIdFromUrl = window.location.pathname.split("/").pop();
    const streamId = streamIdFromInput || streamIdFromUrl;

    $("#liveStreamActivitiesTable").DataTable({
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
            url: `${domainUrl}listLiveStreamActivities`,
            data: function (data) {
                data.live_stream_id = streamId;
            },
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass(
                "pagination-rounded"
            );
        },
    });
});
