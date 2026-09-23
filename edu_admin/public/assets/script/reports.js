$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    const path = window.location.pathname || "";
    if (path.includes("reportPayoutControl")) {
        $(".reportPayoutControlMenu").addClass("menuitem-active");
    } else if (path.includes("reportLivePerformance")) {
        $(".reportLivePerformanceMenu").addClass("menuitem-active");
    } else if (path.includes("reportUserGrowthQuality")) {
        $(".reportUserGrowthQualityMenu").addClass("menuitem-active");
    } else if (path.includes("reportGiftAnalytics")) {
        $(".reportGiftAnalyticsMenu").addClass("menuitem-active");
    } else if (path.includes("reportAgentStatePerformance")) {
        $(".reportAgentStatePerformanceMenu").addClass("menuitem-active");
    } else if (path.includes("reportModerationRisk")) {
        $(".reportModerationRiskMenu").addClass("menuitem-active");
    } else {
        $(".reportRevenueCommissionMenu").addClass("menuitem-active");
    }

    function formatDateInput(dateObj) {
        const y = dateObj.getFullYear();
        const m = String(dateObj.getMonth() + 1).padStart(2, "0");
        const d = String(dateObj.getDate()).padStart(2, "0");
        return `${y}-${m}-${d}`;
    }

    const today = new Date();
    const last30 = new Date();
    last30.setDate(today.getDate() - 30);
    $("#reportStartDate").val(formatDateInput(last30));
    $("#reportEndDate").val(formatDateInput(today));

    function getDateFilters() {
        return {
            start_date: $("#reportStartDate").val() || "",
            end_date: $("#reportEndDate").val() || "",
        };
    }

    function buildReportTable(selector, url) {
        if ($(selector).length === 0) {
            return null;
        }
        return $(selector).DataTable({
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
                url: `${domainUrl}${url}`,
                data: function (data) {
                    const filters = getDateFilters();
                    data.start_date = filters.start_date;
                    data.end_date = filters.end_date;
                },
                error: function (error) {
                    console.log(error);
                },
            },
            drawCallback: function () {
                $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
            },
        });
    }

    const tables = [
        buildReportTable("#revenueCommissionTable", "listRevenueCommissionReport"),
        buildReportTable("#payoutControlTable", "listPayoutControlReport"),
        buildReportTable("#livePerformanceTable", "listLivePerformanceReport"),
        buildReportTable("#userGrowthQualityTable", "listUserGrowthQualityReport"),
        buildReportTable("#giftAnalyticsTable", "listGiftAnalyticsReport"),
        buildReportTable("#agentStatePerformanceTable", "listAgentStatePerformanceReport"),
        buildReportTable("#moderationRiskTable", "listModerationRiskReport"),
    ].filter(function (table) { return table !== null; });

    $("#applyReportFilters").on("click", function () {
        tables.forEach(function (table) {
            table.ajax.reload();
        });
    });

    $("#resetReportFilters").on("click", function () {
        $("#reportStartDate").val(formatDateInput(last30));
        $("#reportEndDate").val(formatDateInput(today));
        tables.forEach(function (table) {
            table.ajax.reload();
        });
    });
});
