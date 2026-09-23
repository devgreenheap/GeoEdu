$(document).ready(function () {
    $("#stateAgentMappingsTable").DataTable({
        autoWidth: false,
        processing: true,
        serverSide: true,
        serverMethod: "post",
        ordering: false,
        columnDefs: [
            { targets: 2, width: "320px" },
            { targets: 3, width: "120px", className: "text-end" },
        ],
        language: {
            paginate: {
                previous: "<i class='mdi mdi-chevron-left'>",
                next: "<i class='mdi mdi-chevron-right'>",
            },
        },
        ajax: {
            url: `${domainUrl}listStateAgentMappings`,
            data: function () {},
            error: (error) => {
                console.log(error);
            },
        },
        drawCallback: function () {
            $(".dataTables_paginate > .pagination").addClass("pagination-rounded");
        },
    });

    $("#stateAgentMappingsTable").on("click", ".save-state-agent", function () {
        checkUserType(() => {
            const stateId = $(this).data("state-id");
            const $row = $(this).closest("tr");
            const agentId = parseInt($row.find(".state-agent-select").val(), 10) || 0;

            if (!stateId) {
                showErrorToast("State is required");
                return;
            }
            if (!agentId) {
                showErrorToast("Please select agent");
                return;
            }

            const formData = new FormData();
            formData.append("state_id", stateId);
            formData.append("agent_id", agentId);

            doAjax(`${domainUrl}saveStateAgentMapping`, formData)
                .then(function (response) {
                    if (response.status) {
                        const updatedUsers = parseInt(response.updated_users || 0, 10);
                        showSuccessToast(`${response.message} (users updated: ${updatedUsers})`);
                        reloadDataTables(["stateAgentMappingsTable"]);
                    } else {
                        showErrorToast(response.message);
                    }
                })
                .catch(function (error) {
                    showErrorToast(error.message);
                });
        });
    });
});
