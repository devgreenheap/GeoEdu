$(document).ready(function () {
    $(".side-nav-item").removeClass("menuitem-active");
    $(".liveDetails").addClass("menuitem-active");

    function updateFrameHeight() {
        const targetHeight = Math.max(window.innerHeight - 220, 520);
        $(".live-details-frame").css("height", `${targetHeight}px`);
    }

    function loadTabFrame($tabLink) {
        const targetSelector = $tabLink.attr("href");
        const url = $tabLink.data("url");
        const frameId = `#live-details-frame-${targetSelector.replace("#", "")}`;
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

    const $firstTab = $(".live-details-tab.active");
    if ($firstTab.length) {
        loadTabFrame($firstTab);
    }

    $(".live-details-tab").on("shown.bs.tab", function () {
        loadTabFrame($(this));
    });
});
