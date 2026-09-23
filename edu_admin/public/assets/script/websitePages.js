$(document).ready(function () {
    "use strict";

    var base = typeof domainUrl !== "undefined" ? domainUrl : "/";

    /* ----------------------------- Helpers ----------------------------- */
    function ok(msg) {
        if (typeof showSuccessToast === "function") showSuccessToast(msg);
    }
    function fail(msg) {
        if (typeof showErrorToast === "function") showErrorToast(msg || "Something went wrong");
        else alert(msg || "Something went wrong");
    }
    function guard(cb) {
        if (typeof checkUserType === "function") checkUserType(cb);
        else cb();
    }

    function postForm(formId, url, successMsg, reload) {
        $(formId).on("submit", function (e) {
            e.preventDefault();
            guard(function () {
                var formData = new FormData($(formId)[0]);
                $.ajax({
                    url: base + url,
                    type: "POST",
                    data: formData,
                    dataType: "json",
                    contentType: false,
                    processData: false,
                    cache: false,
                    success: function (res) {
                        if (res && res.status) {
                            ok(successMsg || res.message);
                            if (reload) setTimeout(function () { location.reload(); }, 700);
                        } else {
                            fail(res && res.message);
                        }
                    },
                    error: function (err) {
                        console.log(err);
                        fail();
                    },
                });
            });
        });
    }

    /* ------------------------- Home image preview ------------------------- */
    $("#heroImageInput").on("change", function () {
        var file = this.files && this.files[0];
        if (file) {
            var reader = new FileReader();
            reader.onload = function (e) {
                $("#heroImagePreview").attr("src", e.target.result).show();
            };
            reader.readAsDataURL(file);
        }
    });

    /* ----------------------------- Quill (About) ----------------------------- */
    var quillAbout = null;
    if (document.getElementById("aboutEditor")) {
        var toolbarOptions = [
            [{ header: [1, 2, 3, false] }],
            ["bold", "italic", "underline", "strike"],
            [{ list: "ordered" }, { list: "bullet" }],
            [{ align: [] }],
            ["link", "image"],
            ["clean"],
        ];

        quillAbout = new Quill("#aboutEditor", {
            theme: "snow",
            modules: {
                toolbar: {
                    container: toolbarOptions,
                    handlers: { image: imageHandler },
                },
            },
        });
    }

    function imageHandler() {
        var input = document.createElement("input");
        input.setAttribute("type", "file");
        input.setAttribute("accept", "image/*");
        input.click();
        input.onchange = function () {
            var file = input.files[0];
            if (!file) return;
            var fd = new FormData();
            fd.append("image", file);
            $.ajax({
                type: "POST",
                url: base + "imageUploadInEditor",
                data: fd,
                contentType: false,
                processData: false,
                success: function (resp) {
                    var url = base + "storage/" + resp.imagePath;
                    var range = quillAbout.getSelection(true);
                    quillAbout.insertEmbed(range.index, "image", url);
                    var img = quillAbout.container.querySelector('img[src="' + url + '"]');
                    if (img) img.setAttribute("width", "100%");
                },
                error: function (e) {
                    console.log(e);
                    fail("Image upload failed");
                },
            });
        };
    }

    /* ----------------------------- Save forms ----------------------------- */
    postForm("#homeContentForm", "saveHomeContent", "Home page updated successfully.", false);
    postForm("#contactForm", "saveContactContent", "Contact info updated successfully.", false);
    postForm("#addFeatureForm", "addHomeFeature", "Feature added.", true);
    postForm("#addScreenshotForm", "addHomeScreenshot", "Screenshot uploaded.", true);

    // About uses Quill content
    $("#aboutForm").on("submit", function (e) {
        e.preventDefault();
        guard(function () {
            var content = quillAbout ? quillAbout.root.innerHTML : "";
            var fd = new FormData();
            fd.append("about_us", content);
            $.ajax({
                url: base + "saveAboutContent",
                type: "POST",
                data: fd,
                dataType: "json",
                contentType: false,
                processData: false,
                success: function (res) {
                    if (res && res.status) ok(res.message);
                    else fail(res && res.message);
                },
                error: function (err) { console.log(err); fail(); },
            });
        });
    });

    /* ----------------------------- Deletes ----------------------------- */
    $(document).on("click", ".delete-feature", function () {
        var id = $(this).data("id");
        if (!confirm("Delete this feature?")) return;
        guard(function () {
            $.post(base + "deleteHomeFeature", { id: id }, function (res) {
                if (res && res.status) { ok(res.message); location.reload(); }
                else fail(res && res.message);
            }, "json").fail(function () { fail(); });
        });
    });

    $(document).on("click", ".delete-screenshot", function () {
        var id = $(this).data("id");
        if (!confirm("Delete this screenshot?")) return;
        guard(function () {
            $.post(base + "deleteHomeScreenshot", { id: id }, function (res) {
                if (res && res.status) { ok(res.message); location.reload(); }
                else fail(res && res.message);
            }, "json").fail(function () { fail(); });
        });
    });
});
