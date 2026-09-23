$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".xpPointsSettings").addClass("menuitem-active");

    $("#xpPointsSettingsForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var url = `${domainUrl}saveXpPointsSettings`;
            var formId = "#xpPointsSettingsForm";
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response) {
                    hideFormSpinner(formId);
                    if (response.status) {
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
});
