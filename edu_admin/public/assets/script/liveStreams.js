$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".liveStreams").addClass("menuitem-active");

    const subCategoryOptions = $("#filter_sub_category_id option")
        .map(function () {
            return {
                value: $(this).attr("value"),
                text: $(this).text(),
                categoryId: $(this).data("category-id"),
            };
        })
        .get()
        .filter((item) => item.value !== "");

    const topicOptions = $("#filter_topic_id option")
        .map(function () {
            return {
                value: $(this).attr("value"),
                text: $(this).text(),
                subCategoryId: $(this).data("sub-category-id"),
            };
        })
        .get()
        .filter((item) => item.value !== "");

    function filterSubCategories(preferredSubCategoryId = null) {
        const selectedCategory = $("#filter_category_id").val();
        const selectedSubCategory = preferredSubCategoryId ?? $("#filter_sub_category_id").val();

        let html = '<option value="">All</option>';
        subCategoryOptions.forEach((item) => {
            if (!selectedCategory || Number(item.categoryId) === Number(selectedCategory)) {
                const selected = Number(selectedSubCategory) === Number(item.value) ? "selected" : "";
                html += `<option value="${item.value}" data-category-id="${item.categoryId}" ${selected}>${item.text}</option>`;
            }
        });
        $("#filter_sub_category_id").html(html);
    }

    function filterTopics(preferredTopicId = null) {
        const selectedSubCategory = $("#filter_sub_category_id").val();
        const selectedTopic = preferredTopicId ?? $("#filter_topic_id").val();

        let html = '<option value="">All</option>';
        topicOptions.forEach((item) => {
            if (!selectedSubCategory || Number(item.subCategoryId) === Number(selectedSubCategory)) {
                const selected = Number(selectedTopic) === Number(item.value) ? "selected" : "";
                html += `<option value="${item.value}" data-sub-category-id="${item.subCategoryId}" ${selected}>${item.text}</option>`;
            }
        });
        $("#filter_topic_id").html(html);
    }

    $("#filter_category_id").on("change", function () {
        filterSubCategories();
        filterTopics();
    });

    $("#filter_sub_category_id").on("change", function () {
        filterTopics();
    });

    const liveStreamsTable = $("#liveStreamsTable").DataTable({
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
            url: `${domainUrl}listLiveStreams`,
            data: function (data) {
                data.filter_date = $("#filter_date").val();
                data.category_id = $("#filter_category_id").val();
                data.sub_category_id = $("#filter_sub_category_id").val();
                data.topic_id = $("#filter_topic_id").val();
                data.language_id = $("#filter_language_id").val();
                data.user_id = $("#filter_user_id").val();
            },
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#applyLiveStreamFilters").on("click", function () {
        liveStreamsTable.ajax.reload();
    });

    $("#resetLiveStreamFilters").on("click", function () {
        $("#filter_date").val("");
        $("#filter_category_id").val("");
        filterSubCategories("");
        filterTopics("");
        $("#filter_language_id").val("");
        $("#filter_user_id").val("");
        liveStreamsTable.ajax.reload();
    });

    filterSubCategories();
    filterTopics();

    // Auto-refresh list every 10 seconds without resetting pagination/search.
    const liveStreamsAutoRefresh = setInterval(function () {
        if (document.visibilityState === "visible") {
            liveStreamsTable.ajax.reload(null, false);
        }
    }, 10000);

    $(window).on("beforeunload", function () {
        clearInterval(liveStreamsAutoRefresh);
    });
});
