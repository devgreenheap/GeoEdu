$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".firebaseAudioRooms").addClass("menuitem-active");

    const firebaseAudioRoomsTable = $("#firebaseAudioRoomsTable").DataTable({
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
            url: `${domainUrl}listFirebaseAudioRooms`,
            data: function (data) {
                data.filter_active = $("#filter_audio_room_active").val();
                data.filter_host_id = $.trim(
                    $("#filter_audio_room_host").val() || ""
                );
            },
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#applyFirebaseAudioRoomFilters").on("click", function () {
        firebaseAudioRoomsTable.ajax.reload();
    });

    $("#resetFirebaseAudioRoomFilters").on("click", function () {
        $("#filter_audio_room_active").val("");
        $("#filter_audio_room_host").val("");
        firebaseAudioRoomsTable.ajax.reload();
    });
});
