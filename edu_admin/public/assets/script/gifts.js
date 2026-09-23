$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".gifts").addClass("menuitem-active");

    $("#editGiftForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var formId = '#editGiftForm';
                var url =  `${domainUrl}editGift`;
                var formdata = collectFormData(formId);
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
    $("#addGiftForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var formId = '#addGiftForm';
                var url =  `${domainUrl}addGift`;
                var formdata = collectFormData(formId);
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

    $("#languageTable").DataTable({
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
            url: `${domainUrl}languageList`,
            data: function (data) {},
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

    $("#gift-list").on("click", ".delete", function (e) {
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
                    var id = $(this).attr("rel");
                    var delete_url =
                        `${domainUrl}deleteGift`;
                        var formData = new FormData();
                        formData.append('id', id);
                        try {
                            doAjax(delete_url, formData).then(function (response){
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
                }
            });
        });
    });


    $('#gift-list').on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var coinPrice = $(this).data("coinprice");
        var categoryId = $(this).data("categoryid");
        var gifturl = $(this).data("gifturl");
        var title = $(this).data("title");
        var animationUrl = $(this).data("animationurl");
        var animationName = $(this).data("animationname");
        var soundUrl = $(this).data("soundurl");
        var soundName = $(this).data("soundname");

        $("#editGiftId").val(id);
        $("#imgEditGiftPreview").attr('src', gifturl);
        $("#editGiftTitle").val(title || '');
        $("#editGiftCoinPrice").val(coinPrice);
        $("#editGiftCategoryId").val(categoryId);

        // Display current animation if uploaded
        if (animationUrl && animationUrl.trim() !== '') {
            $("#editGiftCurrentAnimation").removeClass("d-none");
            $("#editGiftAnimationName").text(animationName || 'animation file');
            $("#editGiftAnimationLink").attr("href", animationUrl);
        } else {
            $("#editGiftCurrentAnimation").addClass("d-none");
            $("#editGiftAnimationLink").attr("href", "#");
        }

        // Display and load current sound if uploaded
        if (soundUrl && soundUrl.trim() !== '') {
            $("#editGiftCurrentSound").removeClass("d-none");
            $("#editGiftSoundName").text(soundName || 'audio file');
            $("#audioEditGiftPreview").find('source').attr('src', soundUrl);
            $("#audioEditGiftPreview")[0].load();
        } else {
            $("#editGiftCurrentSound").addClass("d-none");
            removeAudioSource('#audioEditGiftPreview');
        }

        modalShow('#editGiftModal');
    });

    previewImage('#inputAddGiftImage', '#imgAddGiftPreview');
    previewImage('#inputEditGiftImage', '#imgEditGiftPreview');

    // Preview newly selected sound files immediately
    previewMusic('#addGiftSound', '#audioAddGiftPreview');
    $('#addGiftSound').on('change', function () {
        if (this.files && this.files.length > 0) {
            $('#addGiftSoundPreview').removeClass('d-none');
        } else {
            $('#addGiftSoundPreview').addClass('d-none');
        }
    });

    previewMusic('#editGiftSound', '#audioEditGiftPreview');
    $('#editGiftSound').on('change', function () {
        if (this.files && this.files.length > 0) {
            $('#editGiftCurrentSound').removeClass('d-none');
            $('#editGiftSoundName').text(this.files[0].name + ' (New file selected)');
        }
    });

    // Preview newly selected animation files
    $('#addGiftAnimation').on('change', function () {
        if (this.files && this.files.length > 0) {
            $('#addGiftAnimationFileName').text(this.files[0].name);
            $('#addGiftAnimationPreview').removeClass('d-none');
        } else {
            $('#addGiftAnimationPreview').addClass('d-none');
        }
    });

    $('#editGiftAnimation').on('change', function () {
        if (this.files && this.files.length > 0) {
            $('#editGiftCurrentAnimation').removeClass('d-none');
            $('#editGiftAnimationName').text(this.files[0].name + ' (New file selected)');
            $('#editGiftAnimationLink').addClass('d-none');
        }
    });

    $("#addGiftModal").on("hidden.bs.modal", function () {
        $("#audioAddGiftPreview").trigger("pause");
        removeAudioSource('#audioAddGiftPreview');
        removeImageSource('#imgAddGiftPreview');
        $('#addGiftSoundPreview').addClass('d-none');
        $('#addGiftAnimationPreview').addClass('d-none');
        resetForm('#addGiftForm');
    });

    $("#editGiftModal").on("hidden.bs.modal", function () {
        $("#audioEditGiftPreview").trigger("pause");
        removeAudioSource('#audioEditGiftPreview');
        removeImageSource('#imgEditGiftPreview');
        $('#editGiftAnimationLink').removeClass('d-none');
        resetForm('#editGiftForm');
    });

});
