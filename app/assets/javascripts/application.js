// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, or any plugin's
// vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file. JavaScript code in this file should be added after the last require_* statement.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap.bundle.min.js
//= require jquery.turbolinks
//= require turbolinks
//= require rails-ujs
//= require prototype.js
//= require ajax_scaffold.js
//= require niftycube.js
//= require rico_corner.js
//= require controls.js
//= require dragdrop.js
//= require effects.js
//= require_tree .

var resetForms = function () {
    // this depends on your use
    // this is for foundation 6's abide
    $('form').each(function () {
        $(this).foundation('destroy');
    });
};

document.addEventListener("turbolinks:before-cache", function() {
    resetForms();
});
