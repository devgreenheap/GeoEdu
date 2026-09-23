$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".levels").addClass("menuitem-active");

    const levelsTable = $("#levelsTable").DataTable({
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
            url: `${domainUrl}listUserLevels`,
            data: function (data) {
                data.level_filter = $.trim($("#filter_level_only").val() || "");
                data.include_xp_required = 1;
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

    $("#applyLevelFilter").on("click", function () {
        levelsTable.ajax.reload();
    });

    $("#resetLevelFilter").on("click", function () {
        $("#filter_level_only").val("");
        levelsTable.ajax.reload();
    });

    $("#addLevelForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var level = $.trim($("#level").val() || "");
            $("#level").val(level);
            if (!level) {
                showErrorToast("Level is required");
                return;
            }
            var url = `${domainUrl}addUserLevel`;
            var formId = "#addLevelForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["levelsTable"]);
                        modalHide("#addLevelModal");
                        resetForm(formId);
                        showSuccessToast(response.message);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#editLevelForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}editUserLevel`;
            var formId = "#editLevelForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["levelsTable"]);
                        modalHide("#editLevelModal");
                        resetForm(formId);
                        showSuccessToast(response.message);
                    } else {
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
                console.log("Error! : ", error.message);
                showErrorToast(error.message);
            }
        });
    });

    $("#levelsTable").on("click", ".delete", function (e) {
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
                    var itemId = $(this).attr("rel");
                    var actionUrl = `${domainUrl}deleteUserLevel`;
                    var formData = new FormData();
                    formData.append("id", itemId);
                    try {
                        doAjax(actionUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(["levelsTable"]);
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

    $("#levelsTable").on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var level = $(this).data("level");
        var liveCommentsCount = $(this).data("livecommentscount");
        var hostFollowersCount = $(this).data("hostfollowerscount");
        var sendGiftsCount = $(this).data("sendgiftscount");
        $("#editLevelId").val(id);
        $("#edit_level").val(level);
        $("#edit_live_comments_count").val(liveCommentsCount);
        $("#edit_host_followers_count").val(hostFollowersCount);
        $("#edit_send_gifts_count").val(sendGiftsCount);
        modalShow("#editLevelModal");
    });
});
