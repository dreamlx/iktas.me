$(function() {
    $('#gallerys').slidesjs({
        width: 960,
        height: 480,
        navigation: false,
        start: 1,
        play: {
          auto: true
        }
    });
    $(".m").click(function() {
        $(".menu").toggle();
    });
});