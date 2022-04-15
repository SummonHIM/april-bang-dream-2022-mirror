// JavaScript Document

//prof
$(function () {
  $('.character_profile').hide();
  $('.character_profile#himari').show();
  $('.character_select ul a').on('click', function () {
    $('.character_profile').not($($(this).attr('href'))).hide();
    $($(this).attr('href')).fadeIn();
  });
});

//link
$(function () {
  $('a[href^="#"]').click(function () {
    var speed = 500;
    var href = $(this).attr("href");
    var target = $(href == "#" || href == "" ? 'html' : href);
    var position = target.offset().top;
    $("html, body").animate({
      scrollTop: position
    }, speed, "swing");
    return false;
  });
});


//nav
$(function () {
  $('.menu_trigger').on('click', function () {
    if ($(this).hasClass('menu_active')) {
      $(this).removeClass('menu_active');
      $('.gnav_menu').removeClass('gnav_menu_open');
      $('main, .main_visual, footer').removeClass('menu_open_blur');


    } else {
      $(this).addClass('menu_active');
      $('.gnav_menu').addClass('gnav_menu_open');
      $('main, .main_visual, footer').addClass('menu_open_blur');

    }
  });
  $('.gnav_menu').on('click', function () {
    if ($(this).hasClass('gnav_menu_open')) {
      $(this).removeClass('gnav_menu_open');
      $('.menu_trigger').removeClass('menu_active');
      $('.gnav_menu').removeClass('gnav_menu_open');
      $('main, .main_visual, footer').removeClass('menu_open_blur');

    }
  });
  //リンククリックでメニュー閉じる
  $('.gnav_menu a').on('click', function () {
    $('.menu_trigger').removeClass('menu_active');
    $('.gnav_menu').removeClass('gnav_menu_open');
    $('main, .main_visual, footer').removeClass('menu_open_blur');

  });
});


//footer_fix_btn
  $(function() {
      setInterval(function() {
        $('.footer_fix_btn').animate({'bottom': '0px' }, 800);
      }, 1000);

    });


//modal
$(function () {
  $('.modal_open').click(function () {
    $("body").addClass("no_scroll");
    var id = $(this).data('id');
    $('.modal_overlay, .modal_window[data-id="modal_' + id + '"]').fadeIn();
  });
  $('.modal_close , .modal_overlay').click(function () {
    $("body").removeClass("no_scroll");
    $('.modal_overlay, .modal_window').fadeOut();
  });
});

//sakura
$(document).ready(function () {
  $(document).snowfall({
    image: [
      './images/effect_sakura01.png',
      './images/effect_sakura02.png',
      './images/effect_sakura03.png',
      './images/effect_sakura04.png',
      './images/effect_sakura05.png'
    ],
    flakeCount: 20,
    maxSpeed: 2,
    minSpeed: 1,
    maxSize: 50,
    minSize: 10,
    shadow: false
  });
});

//animete
$(function(){
  $(".fadeup").on("inview", function (event, isInView) {
    if (isInView) {
      $(this).stop().addClass("is_inview");
    }
  });
  $(".fadein").on("inview", function (event, isInView) {
    if (isInView) {
      $(this).stop().addClass("is_inview");
    }
  });
});

