$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".packageDetails").addClass("menuitem-active");

    function applyFaqFilter() {
        var category = ($("#faqCategoryFilter").val() || "all").toLowerCase();
        $(".faq-card").each(function () {
            var itemCategory = ($(this).data("category") || "diamond").toLowerCase();
            $(this).toggle(category === "all" || itemCategory === category);
        });
    }

    $("#faqCategoryFilter").on("change", applyFaqFilter);
    applyFaqFilter();

    $("#addDiamondFaqForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var category = ($("#faq_category").val() || "").toLowerCase();
            var question = $.trim($("#faq_question").val() || "");
            var answer = $.trim($("#faq_answer").val() || "");
            $("#faq_category").val(category);
            $("#faq_question").val(question);
            $("#faq_answer").val(answer);
            if (!category) {
                showErrorToast("Category is required");
                return;
            }
            if (!question) {
                showErrorToast("Question is required");
                return;
            }
            if (!answer) {
                showErrorToast("Answer is required");
                return;
            }

            var formId = "#addDiamondFaqForm";
            var url = `${domainUrl}addDiamondFaq`;
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            doAjax(url, formdata)
                .then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
                    } else {
                        showErrorToast(response.message);
                    }
                })
                .catch(function (error) {
                    hideFormSpinner(formId);
                    showErrorToast(error.message);
                });
        });
    });

    $("#editDiamondFaqForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var category = ($("#edit_faq_category").val() || "").toLowerCase();
            var question = $.trim($("#edit_faq_question").val() || "");
            var answer = $.trim($("#edit_faq_answer").val() || "");
            $("#edit_faq_category").val(category);
            $("#edit_faq_question").val(question);
            $("#edit_faq_answer").val(answer);
            if (!category) {
                showErrorToast("Category is required");
                return;
            }
            if (!question) {
                showErrorToast("Question is required");
                return;
            }
            if (!answer) {
                showErrorToast("Answer is required");
                return;
            }

            var formId = "#editDiamondFaqForm";
            var url = `${domainUrl}editDiamondFaq`;
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            doAjax(url, formdata)
                .then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
                        location.reload();
                    } else {
                        showErrorToast(response.message);
                    }
                })
                .catch(function (error) {
                    hideFormSpinner(formId);
                    showErrorToast(error.message);
                });
        });
    });

    $("#diamond-faq-list").on("click", ".delete", function (e) {
        e.preventDefault();
        checkUserType(() => {
            Swal.fire({
                icon: "info",
                title: "Are you sure?",
                showDenyButton: true,
                denyButtonText: "Cancel",
                confirmButtonText: "Yes",
            }).then((result) => {
                if (result.isConfirmed) {
                    var id = $(this).attr("rel");
                    var url = `${domainUrl}deleteDiamondFaq`;
                    var formData = new FormData();
                    formData.append("id", id);
                    doAjax(url, formData)
                        .then(function (response) {
                            if (response.status) {
                                location.reload();
                            } else {
                                showErrorToast(response.message);
                            }
                        })
                        .catch(function (error) {
                            showErrorToast(error.message);
                        });
                }
            });
        });
    });

    $("#diamond-faq-list").on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var category = $(this).data("category");
        var question = $(this).data("question");
        var answer = $(this).data("answer");
        $("#editDiamondFaqId").val(id);
        $("#edit_faq_category").val(category);
        $("#edit_faq_question").val(question);
        $("#edit_faq_answer").val(answer);
        modalShow("#editDiamondFaqModal");
    });
});
