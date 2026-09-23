$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".entryEffects").addClass("menuitem-active");
    let currentEntryEffectUrl = "";
    let svgaPlayer = null;
    let svgaParser = null;

    function resetSvgaPreview() {
        $("#entryEffectSvgaLoading").addClass("d-none");
        $("#entryEffectSvgaError").addClass("d-none").text("");
        if (svgaPlayer && typeof svgaPlayer.clear === "function") {
            svgaPlayer.clear();
        }
        if (svgaPlayer && typeof svgaPlayer.stopAnimation === "function") {
            svgaPlayer.stopAnimation(true);
        }
        $("#entryEffectSvgaCanvas").empty();
        svgaPlayer = null;
        svgaParser = null;
    }

    function showSvgaPreviewError(message) {
        $("#entryEffectSvgaLoading").addClass("d-none");
        $("#entryEffectSvgaError").removeClass("d-none").text(message);
    }

    function playCurrentEntryEffect() {
        resetSvgaPreview();

        if (!currentEntryEffectUrl) {
            showSvgaPreviewError("Current SVGA file not found");
            return;
        }

        if (
            typeof window.SVGA === "undefined" ||
            typeof window.SVGA.Player !== "function" ||
            typeof window.SVGA.Parser !== "function"
        ) {
            showSvgaPreviewError("SVGA player could not be loaded");
            return;
        }

        $("#entryEffectSvgaLoading").removeClass("d-none");

        try {
            svgaPlayer = new window.SVGA.Player("#entryEffectSvgaCanvas");
            svgaParser = new window.SVGA.Parser("#entryEffectSvgaCanvas");
            svgaPlayer.loops = 0;
            svgaPlayer.clearsAfterStop = false;
            svgaParser.load(
                currentEntryEffectUrl,
                function (videoItem) {
                    $("#entryEffectSvgaLoading").addClass("d-none");
                    svgaPlayer.setVideoItem(videoItem);
                    svgaPlayer.startAnimation();
                },
                function () {
                    showSvgaPreviewError("Unable to play this SVGA file");
                }
            );
        } catch (error) {
            console.log("Error! : ", error.message);
            showSvgaPreviewError("Unable to play this SVGA file");
        }
    }

    $("#editEntryEffectForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var editTitle = $.trim($("#editEntryEffectTitle").val() || "");
                $("#editEntryEffectTitle").val(editTitle);
                if (!editTitle) {
                    showErrorToast("Title is required");
                    return;
                }
                var formId = '#editEntryEffectForm';
                var url =  `${domainUrl}editEntryEffect`;
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
    $("#addEntryEffectForm").on("submit", function (e) {
        e.preventDefault();
            checkUserType(() => {
                var title = $.trim($("#title").val() || "");
                $("#title").val(title);
                if (!title) {
                    showErrorToast("Title is required");
                    return;
                }
                var formId = '#addEntryEffectForm';
                var url =  `${domainUrl}addEntryEffect`;
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

    $("#entry-effect-list").on("click", ".delete", function (e) {
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
                        `${domainUrl}deleteEntryEffect`;
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


    $('#entry-effect-list').on("click", ".edit", function (e) {
        e.preventDefault();
        var id = $(this).attr("rel");
        var title = $(this).data("title");
        var coinPrice = $(this).data("coinprice");
        var duration = $(this).data("duration");
        var effecturl = $(this).data("effecturl");

        $("#editEntryEffectId").val(id);
        currentEntryEffectUrl = effecturl || "";
        $("#currentEntryEffectFileLink").removeClass("d-none");
        $("#editEntryEffectTitle").val(title);
        $("#editEntryEffectStarPrice").val(coinPrice);
        $("#editEntryEffectDuration").val(duration);

        modalShow('#editEntryEffectModal');
    });

    $("#entry-effect-list").on("click", ".preview-entry-effect", function (e) {
        e.preventDefault();
        currentEntryEffectUrl = $(this).data("effecturl") || "";
        modalShow("#previewEntryEffectModal");
    });

    $("#currentEntryEffectFileLink").on("click", function (e) {
        e.preventDefault();
        modalShow("#previewEntryEffectModal");
    });

    $("#previewEntryEffectModal").on("shown.bs.modal", function () {
        playCurrentEntryEffect();
    });

    $("#previewEntryEffectModal").on("hidden.bs.modal", function () {
        resetSvgaPreview();
    });


    $("#addEntryEffectModal").on("hidden.bs.modal", function () {
        resetForm('#addEntryEffectForm');
    });
    $("#editEntryEffectModal").on("hidden.bs.modal", function () {
        currentEntryEffectUrl = "";
        $("#currentEntryEffectFileLink").addClass("d-none");
        resetForm('#editEntryEffectForm');
    });

});
