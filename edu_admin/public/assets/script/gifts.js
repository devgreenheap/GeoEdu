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
            doAjax(url, formdata).then(function (response){
                hideFormSpinner(formId);
                if(response.status){
                    location.reload();
                }else{
                    showErrorToast(response.message || 'Failed to update gift');
                }
            }).catch(function (xhr) {
                hideFormSpinner(formId);
                var msg = 'Upload failed. ';
                if (xhr.status === 413) {
                    msg += 'The file is too large for the server (HTTP 413).';
                } else if (xhr.responseJSON && xhr.responseJSON.message) {
                    msg = xhr.responseJSON.message;
                } else {
                    msg += (xhr.statusText || 'Please try again.');
                }
                showErrorToast(msg);
            });
        });
    });

    $("#addGiftForm").on("submit", function (e) {
        e.preventDefault();
        checkUserType(() => {
            var formId = '#addGiftForm';
            var url =  `${domainUrl}addGift`;
            var formdata = collectFormData(formId);
            showFormSpinner(formId);
            doAjax(url, formdata).then(function (response){
                hideFormSpinner(formId);
                if(response.status){
                    location.reload();
                }else{
                    showErrorToast(response.message || 'Failed to add gift');
                }
            }).catch(function (xhr) {
                hideFormSpinner(formId);
                var msg = 'Upload failed. ';
                if (xhr.status === 413) {
                    msg += 'The file is too large for the server (HTTP 413).';
                } else if (xhr.responseJSON && xhr.responseJSON.message) {
                    msg = xhr.responseJSON.message;
                } else {
                    msg += (xhr.statusText || 'Please try again.');
                }
                showErrorToast(msg);
            });
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

    var MAX_IMAGE_SIZE = 20 * 1024 * 1024; // 20MB
    var MAX_ANIMATION_SIZE = 50 * 1024 * 1024; // 50MB
    var MAX_SOUND_SIZE = 30 * 1024 * 1024; // 30MB

    $('#inputAddGiftImage, #inputEditGiftImage').on('change', function () {
        if (this.files && this.files.length > 0) {
            var file = this.files[0];
            if (file.size > MAX_IMAGE_SIZE) {
                showErrorToast('Image size exceeds 20MB limit');
                $(this).val('');
                return;
            }
        }
    });

    previewImage('#inputAddGiftImage', '#imgAddGiftPreview');
    previewImage('#inputEditGiftImage', '#imgEditGiftPreview');

    // Preview newly selected sound files immediately
    previewMusic('#addGiftSound', '#audioAddGiftPreview');
    $('#addGiftSound').on('change', function () {
        if (this.files && this.files.length > 0) {
            var file = this.files[0];
            if (file.size > MAX_SOUND_SIZE) {
                showErrorToast('Sound file size exceeds 30MB limit');
                $(this).val('');
                $('#addGiftSoundPreview').addClass('d-none');
                return;
            }
            $('#addGiftSoundPreview').removeClass('d-none');
        } else {
            $('#addGiftSoundPreview').addClass('d-none');
        }
    });

    previewMusic('#editGiftSound', '#audioEditGiftPreview');
    $('#editGiftSound').on('change', function () {
        if (this.files && this.files.length > 0) {
            var file = this.files[0];
            if (file.size > MAX_SOUND_SIZE) {
                showErrorToast('Sound file size exceeds 30MB limit');
                $(this).val('');
                return;
            }
            $('#editGiftCurrentSound').removeClass('d-none');
            $('#editGiftSoundName').text(file.name + ' (New file selected)');
        }
    });

    // Preview newly selected animation files
    $('#addGiftAnimation').on('change', function () {
        if (this.files && this.files.length > 0) {
            var file = this.files[0];
            var ext = file.name.split('.').pop().toLowerCase();
            var allowed = ['svga', 'svg', 'gif', 'png', 'webp', 'mp4', 'json'];
            if (!allowed.includes(ext)) {
                showErrorToast('Animation must be .svga, .svg, .gif, .png, .webp, or .mp4');
                $(this).val('');
                $('#addGiftAnimationPreview').addClass('d-none');
                return;
            }
            if (file.size > MAX_ANIMATION_SIZE) {
                showErrorToast('Animation file size exceeds 50MB limit');
                $(this).val('');
                $('#addGiftAnimationPreview').addClass('d-none');
                return;
            }
            $('#addGiftAnimationFileName').text(file.name);
            $('#addGiftAnimationPreview').removeClass('d-none');
        } else {
            $('#addGiftAnimationPreview').addClass('d-none');
        }
    });

    $('#editGiftAnimation').on('change', function () {
        if (this.files && this.files.length > 0) {
            var file = this.files[0];
            var ext = file.name.split('.').pop().toLowerCase();
            var allowed = ['svga', 'svg', 'gif', 'png', 'webp', 'mp4', 'json'];
            if (!allowed.includes(ext)) {
                showErrorToast('Animation must be .svga, .svg, .gif, .png, .webp, or .mp4');
                $(this).val('');
                return;
            }
            if (file.size > MAX_ANIMATION_SIZE) {
                showErrorToast('Animation file size exceeds 50MB limit');
                $(this).val('');
                return;
            }
            $('#editGiftCurrentAnimation').removeClass('d-none');
            $('#editGiftAnimationName').text(file.name + ' (New file selected)');
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
