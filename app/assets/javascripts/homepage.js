$.onmount("#carouselPausePlayButton", function () {
    $(this).on('click', function() {
        if ($(this).attr('data-state') === "pause") {
            $('#myCarousel').carousel('cycle');
            $(this).attr('data-state', "play");
        } else {
            $('#myCarousel').carousel('pause');
            $(this).attr('data-state', "pause");
        }
        $('#myCarousel').find('span').toggleClass('glyphicon-pause').toggleClass('glyphicon-play');
    })
});