$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".firebaseChats").addClass("menuitem-active");
    const chatUsers = Array.isArray(window.firebaseChatUsers)
        ? window.firebaseChatUsers
        : [];

    const firebaseChatsTable = $("#firebaseChatsTable").DataTable({
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
            url: `${domainUrl}listFirebaseChats`,
            data: function (data) {
                data.filter_date = $("#filter_chat_date").val();
                data.sender = $.trim($("#filter_chat_sender").val() || "");
                data.receiver = $.trim($("#filter_chat_receiver").val() || "");
            },
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#applyFirebaseChatFilters").on("click", function () {
        firebaseChatsTable.ajax.reload();
    });

    $("#resetFirebaseChatFilters").on("click", function () {
        $("#filter_chat_date").val("");
        $("#filter_chat_sender").val("");
        $("#filter_chat_receiver").val("");
        firebaseChatsTable.ajax.reload();
    });

    bindAutocomplete("#filter_chat_sender", "#filter_chat_sender_list");
    bindAutocomplete("#filter_chat_receiver", "#filter_chat_receiver_list");

    function bindAutocomplete(inputSelector, listSelector) {
        const $input = $(inputSelector);
        const $list = $(listSelector);

        function renderList(term) {
            const query = (term || "").toLowerCase();
            if (!query) {
                $list.hide().empty();
                return;
            }

            const matches = chatUsers
                .filter((name) => String(name).toLowerCase().includes(query))
                .slice(0, 6);

            if (matches.length === 0) {
                $list.hide().empty();
                return;
            }

            $list.empty();
            matches.forEach((name) => {
                const $item = $("<div>")
                    .addClass("chat-autocomplete-item")
                    .text(name)
                    .on("click", function () {
                        $input.val(name);
                        $list.hide().empty();
                    });
                $list.append($item);
            });
            $list.show();
        }

        $input.on("input focus", function () {
            renderList($(this).val());
        });

        $(document).on("click", function (e) {
            if (
                !$(e.target).closest(inputSelector).length &&
                !$(e.target).closest(listSelector).length
            ) {
                $list.hide().empty();
            }
        });
    }
});
