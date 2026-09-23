$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".categoryDetails").addClass("menuitem-active");

    function updateFrameHeight() {
        const targetHeight = Math.max(window.innerHeight - 220, 520);
        $(".category-details-frame").css("height", `${targetHeight}px`);
    }

    function loadTabFrame($tabLink) {
        const targetSelector = $tabLink.attr("href");
        const url = $tabLink.data("url");
        const frameId = `#category-details-frame-${targetSelector.replace("#", "")}`;
        const $frame = $(frameId);

        if ($frame.length === 0 || !url) {
            return;
        }
        if ($frame.attr("data-loaded") === "1") {
            return;
        }

        $frame.attr("src", url);
        $frame.attr("data-loaded", "1");
    }

    updateFrameHeight();
    $(window).on("resize", updateFrameHeight);

    const $firstTab = $(".category-details-tab.active");
    if ($firstTab.length) {
        loadTabFrame($firstTab);
    }

    $(".category-details-tab").on("shown.bs.tab", function () {
        loadTabFrame($(this));
    });
});
