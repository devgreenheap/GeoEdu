$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".users").addClass("menuitem-active");

    function updateEmbeddedFramesHeight() {
        const targetHeight = Math.max(window.innerHeight - 260, 560);
        $("#hostAgentRequestsFrame").css("height", `${targetHeight}px`);
        $("#stateAgentMappingsFrame").css("height", `${targetHeight}px`);
        $("#screenshotDisableRequestsFrame").css("height", `${targetHeight}px`);
    }

    function loadFrameOnce(frameSelector, src) {
        const $frame = $(frameSelector);
        if ($frame.length === 0 || $frame.attr("data-loaded") === "1") {
            return;
        }
        $frame.attr("src", src);
        $frame.attr("data-loaded", "1");
    }

    updateEmbeddedFramesHeight();
    $(window).on("resize", updateEmbeddedFramesHeight);

    $('a[data-bs-toggle="pill"][href="#v-pills-host-agent-requests"]').on("shown.bs.tab", function () {
        loadFrameOnce("#hostAgentRequestsFrame", `${domainUrl}hostAgentRequests?embed=1`);
        updateEmbeddedFramesHeight();
    });

    $('a[data-bs-toggle="pill"][href="#v-pills-state-agent"]').on("shown.bs.tab", function () {
        loadFrameOnce("#stateAgentMappingsFrame", `${domainUrl}stateAgentMappings?embed=1`);
        updateEmbeddedFramesHeight();
    });

    $('a[data-bs-toggle="pill"][href="#v-pills-screenshot-disable"]').on("shown.bs.tab", function () {
        loadFrameOnce("#screenshotDisableRequestsFrame", `${domainUrl}screenshotDisableRequests?embed=1`);
        updateEmbeddedFramesHeight();
    });

    function getUsersFilters() {
        return {
            level_id: $("#filterLevelId").val() || "",
            user_type: $("#filterUserType").val() || "all",
            role_type: $("#filterRoleType").val() || "all",
            filter_name: $.trim($("#filterUserName").val() || ""),
            mobile: $.trim($("#filterMobile").val() || ""),
        };
    }

    const usersTable = $("#usersTable").DataTable({
        autoWidth: false,
        processing: true,
        serverSide: true,
        serverMethod: "post",
        ordering: false,
        columnDefs: [
            { targets: 0, width: "60px" },
            { targets: -1, width: "140px", className: "text-end" },
        ],
        language: {
            paginate: {
                previous: "<i class='mdi mdi-chevron-left'>",
                next: "<i class='mdi mdi-chevron-right'>",
            },
        },
        ajax: {
            url: `${domainUrl}listAllUsers`,
            data: function (data) {
                const filters = getUsersFilters();
                data.level_id = filters.level_id;
                data.user_type = filters.user_type;
                data.role_type = filters.role_type;
                data.filter_name = filters.filter_name;
                data.mobile = filters.mobile;
            },
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#applyUsersFilter").on("click", function () {
        usersTable.ajax.reload();
    });

    $("#resetUsersFilter").on("click", function () {
        $("#filterLevelId").val("");
        $("#filterUserType").val("all");
        $("#filterRoleType").val("all");
        $("#filterUserName").val("");
        $("#filterUserId").val("");
        $("#filterMobile").val("");
        $("#nameAutocompleteList").addClass("d-none").empty();
        usersTable.ajax.reload();
    });

    let autocompleteTimer = null;

    function renderNameSuggestions(items) {
        const $list = $("#nameAutocompleteList");
        $list.empty();

        if (!items || !items.length) {
            $list.addClass("d-none");
            return;
        }

        items.forEach(function (item) {
            const username = item.username || "-";
            const fullname = item.fullname || "-";
            const mobile = item.user_mobile_no || "-";
            const label = `${username} (${fullname}) - ${mobile}`;
            const escapedLabel = $("<div>").text(label).html();
            const escapedUsername = $("<div>").text(username).html();

            const row = `<a href="#" class="list-group-item list-group-item-action user-name-suggestion" data-id="${item.id}" data-name="${escapedUsername}">${escapedLabel}</a>`;
            $list.append(row);
        });

        $list.removeClass("d-none");
    }

    $("#filterUserName").on("input", function () {
        const query = $.trim($(this).val() || "");
        $("#filterUserId").val("");

        if (autocompleteTimer) {
            clearTimeout(autocompleteTimer);
        }

        if (query.length < 1) {
            $("#nameAutocompleteList").addClass("d-none").empty();
            return;
        }

        autocompleteTimer = setTimeout(function () {
            const formData = new FormData();
            formData.append("q", query);

            doAjax(`${domainUrl}searchUsersForFilter`, formData)
                .then(function (response) {
                    if (response.status) {
                        renderNameSuggestions(response.data || []);
                    } else {
                        $("#nameAutocompleteList").addClass("d-none").empty();
                    }
                })
                .catch(function () {
                    $("#nameAutocompleteList").addClass("d-none").empty();
                });
        }, 250);
    });

    $(document).on("click", ".user-name-suggestion", function (e) {
        e.preventDefault();
        const selectedName = $(this).data("name") || "";
        const selectedId = $(this).data("id") || "";
        $("#filterUserName").val(selectedName);
        $("#filterUserId").val(selectedId);
        $("#nameAutocompleteList").addClass("d-none").empty();
    });

    $(document).on("click", function (e) {
        const $target = $(e.target);
        if (!$target.closest("#filterUserName").length && !$target.closest("#nameAutocompleteList").length) {
            $("#nameAutocompleteList").addClass("d-none").empty();
        }
    });

    $(document).on("change", ".freezeUser", function () {
        checkUserType(() => {
            const userId = $(this).attr("rel");
            const value = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}userFreezeUnfreeze`,
                data: {
                    user_id: userId,
                    is_freez: value,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        usersTable.ajax.reload(null, false);
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

    $(document).on("change", ".moderatorUser", function () {
        checkUserType(() => {
            const userId = $(this).attr("rel");
            const value = $(this).is(":checked") ? 1 : 0;
            $.ajax({
                type: "POST",
                url: `${domainUrl}changeUserModeratorStatus`,
                data: {
                    user_id: userId,
                    is_moderator: value,
                },
                success: function (response) {
                    if (response.status) {
                        showSuccessToast(response.message);
                        usersTable.ajax.reload(null, false);
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
});
