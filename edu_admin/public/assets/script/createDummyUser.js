$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");

    function filterSubCategories() {
        const selectedCategory = $("#category_id").val();
        $("#sub_category_id option").each(function () {
            const categoryId = $(this).data("category-id");
            if (!categoryId || !selectedCategory || Number(categoryId) === Number(selectedCategory)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });

        const selectedSubCategory = $("#sub_category_id option:selected");
        if (selectedSubCategory.length && selectedSubCategory.is(":hidden")) {
            $("#sub_category_id").val("");
        }
        $("#sub_category_id").trigger("change.select2");
    }

    function filterTopics() {
        const selectedSubCategory = $("#sub_category_id").val();
        $("#topic_id option").each(function () {
            const subCategoryId = $(this).data("sub-category-id");
            if (!subCategoryId || !selectedSubCategory || Number(subCategoryId) === Number(selectedSubCategory)) {
                $(this).show();
            } else {
                $(this).hide();
            }
        });

        const selectedTopic = $("#topic_id option:selected");
        if (selectedTopic.length && selectedTopic.is(":hidden")) {
            $("#topic_id").val("");
        }
        $("#topic_id").trigger("change.select2");
    }

    $("#category_id").on("change", function () {
        filterSubCategories();
        filterTopics();
    });

    $("#sub_category_id").on("change", function () {
        filterTopics();
    });

    $("#createDummyUserForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var url =  `${domainUrl}addDummyUser`;
                var formId = '#createDummyUserForm';
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
                        showSuccessToast(response.message);
                        window.location.href = `${domainUrl}users`;
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

    previewImage('#profile_photo', '#img-profile');
    filterSubCategories();
    filterTopics();

});
