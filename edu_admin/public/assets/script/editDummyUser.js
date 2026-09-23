$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");

    const subCategoryOptions = $("#sub_category_id option").map(function () {
        return {
            value: $(this).attr("value"),
            text: $(this).text(),
            categoryId: $(this).data("category-id"),
        };
    }).get().filter((item) => item.value !== "");

    const topicOptions = $("#topic_id option").map(function () {
        return {
            value: $(this).attr("value"),
            text: $(this).text(),
            subCategoryId: $(this).data("sub-category-id"),
        };
    }).get().filter((item) => item.value !== "");

    const stateOptions = $("#state option").map(function () {
        return {
            value: $(this).attr("value"),
            text: $(this).text(),
            countryName: $(this).data("country-name"),
        };
    }).get().filter((item) => item.value !== "");

    function filterSubCategories(preferredSubCategoryId = null) {
        const selectedCategory = $("#category_id").val();
        const selectedSubCategory = preferredSubCategoryId ?? $("#sub_category_id").val();

        let html = '<option value="">Select Sub Category</option>';
        subCategoryOptions.forEach((item) => {
            if (!selectedCategory || Number(item.categoryId) === Number(selectedCategory)) {
                const selected = Number(selectedSubCategory) === Number(item.value) ? "selected" : "";
                html += `<option value="${item.value}" data-category-id="${item.categoryId}" ${selected}>${item.text}</option>`;
            }
        });

        $("#sub_category_id").html(html).trigger("change");
    }

    function filterTopics(preferredTopicId = null) {
        const selectedSubCategory = $("#sub_category_id").val();
        const selectedTopic = preferredTopicId ?? $("#topic_id").val();

        let html = '<option value="">Select Topic</option>';
        topicOptions.forEach((item) => {
            if (!selectedSubCategory || Number(item.subCategoryId) === Number(selectedSubCategory)) {
                const selected = Number(selectedTopic) === Number(item.value) ? "selected" : "";
                html += `<option value="${item.value}" data-sub-category-id="${item.subCategoryId}" ${selected}>${item.text}</option>`;
            }
        });

        $("#topic_id").html(html).trigger("change");
    }

    function filterStates(preferredState = null) {
        const selectedCountry = ($("#country").val() || "").toString().trim().toLowerCase();
        const selectedState = (preferredState ?? $("#state").val() ?? "").toString().trim().toLowerCase();

        let html = '<option value="">Select State</option>';
        stateOptions.forEach((item) => {
            const itemCountry = (item.countryName || "").toString().trim().toLowerCase();
            if (!selectedCountry || itemCountry === selectedCountry) {
                const isSelected = selectedState && selectedState === (item.value || "").toString().trim().toLowerCase();
                html += `<option value="${item.value}" data-country-name="${item.countryName || ""}" ${isSelected ? "selected" : ""}>${item.text}</option>`;
            }
        });

        $("#state").html(html).trigger("change");
    }

    $("#category_id").on("change", function () {
        filterSubCategories();
        filterTopics();
    });

    $("#sub_category_id").on("change", function () {
        filterTopics();
    });

    $("#country").on("change", function () {
        filterStates();
    });

    $("#editDummyUserForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var url =  `${domainUrl}updateDummyUser`;
                var formId = '#editDummyUserForm';
                var formdata = collectFormData(formId);
                var is_verify = $("#switchIsVerify").prop("checked") == true ? 1 : 0;
                var is_adult = $("#switchIsAdult").prop("checked") == true ? 1 : 0;
                formdata.append('is_verify', is_verify);
                formdata.append('is_adult', is_adult);

                showFormSpinner(formId);
            try {
                doAjax(url, formdata).then(function (response){
                    hideFormSpinner(formId);
                    if(response.status){
                        location.reload();
                    }else{
                        showErrorToast(response.message);
                    }
                });
            } catch (error) {
            console.log('Error! : ', error.message);
                showErrorToast(error.message);
            }
        });
    });

    previewImage('#profile_photo', '#imgUserProfile-userDetails');
    const initialSubCategoryId = $("#sub_category_id").val();
    const initialTopicId = $("#topic_id").val();
    const initialState = $("#state").val();
    filterSubCategories(initialSubCategoryId);
    filterTopics(initialTopicId);
    filterStates(initialState);

});
