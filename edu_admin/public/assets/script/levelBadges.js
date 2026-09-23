$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".levelBadges").addClass("menuitem-active");

    $("#levelBadgesTable").DataTable({
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
            url: `${domainUrl}listLevelBadges`,
            data: function () {},
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

    $("#addLevelBadgeForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}addLevelBadge`;
            var formId = "#addLevelBadgeForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["levelBadgesTable"]);
                        modalHide("#addLevelBadgeModal");
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

    $("#editLevelBadgeForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}editLevelBadge`;
            var formId = "#editLevelBadgeForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        reloadDataTables(["levelBadgesTable"]);
                        modalHide("#editLevelBadgeModal");
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

    $("#levelBadgesTable").on("click", ".delete", function (e) {
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
                    var actionUrl = `${domainUrl}deleteLevelBadge`;
                    var formData = new FormData();
                    formData.append("id", itemId);
                    try {
                        doAjax(actionUrl, formData).then(function (response) {
                            if (response.status) {
                                reloadDataTables(["levelBadgesTable"]);
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

    $("#levelBadgesTable").on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var title = $(this).data("title");
        var startLevel = $(this).data("startlevel");
        var endLevel = $(this).data("endlevel");
        var image = $(this).data("image");
        $("#editLevelBadgeId").val(id);
        $("#edit_title").val(title);
        $("#edit_start_level").val(startLevel);
        $("#edit_end_level").val(endLevel);
        $("#imgEditLevelBadgePreview").attr("src", image);
        modalShow("#editLevelBadgeModal");
    });

    $("#image").on("change", function (e) {
        const [file] = e.target.files;
        if (file) {
            $("#imgAddLevelBadgePreview").attr("src", URL.createObjectURL(file));
        }
    });

    $("#edit_image").on("change", function (e) {
        const [file] = e.target.files;
        if (file) {
            $("#imgEditLevelBadgePreview").attr(
                "src",
                URL.createObjectURL(file)
            );
        }
    });
});
