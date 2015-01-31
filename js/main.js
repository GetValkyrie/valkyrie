
$.stellar.positionProperty.translate = {
  setPosition: function(element, newLeft, originalLeft, newTop, originalTop) {
    var distance = newTop - originalTop;
    var rate = $(window).height() / 5;

    if(element.hasClass('valkyrie-background')) {
      var windowHeight = $(window).height();
      var parallaxHeight = element.height();
      var scrollTop = $(window).scrollTop();
      var offsetTop = element.offset().top;
      var documentHeight = $(document).height();
      if(offsetTop < windowHeight + scrollTop) {
        var opacity = ((parallaxHeight - (documentHeight - scrollTop - windowHeight))/parallaxHeight)*0.6;
        element.css('opacity', opacity);
      }
    }
    else {
      element.css('transform', 'translate3d(0, ' + distance + 'px, 0');
    }
  },
};

$(function(){
  if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent) == false) {
    $.stellar({
      hideDistantElements: 1,
      positionProperty: 'translate',
    });
  }
})

$(document).ready(function(){
  $mask = $('.epic-drupal-development .mask');
  var maskOffsetTop = $mask.offset().top;

  $(window).on('scroll resize', function(){
    if($(window).scrollTop() > ($('.epic-drupal-development').outerHeight() - $mask.outerHeight())) {
      $mask.addClass('fixed-position-command-line background-for-header');
      $('header #logo').addClass('showed-logo');
    }
    else {
      $mask.removeClass('fixed-position-command-line background-for-header');
      $('header #logo').removeClass('showed-logo');
    }
  });
})