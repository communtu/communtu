// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require jquery-ui

function user_profile_edit_show_category(id) {
    $$('div.category_active')[0].removeClassName('category_active') ;
    $('category_'+id).addClassName('category_active');

    var test = $$('div.bundle_category_active');
    var test2 = $$('div.bundle_category_active').size();
    var xxx=2;


    if (!$('category_bundle_'+id).hasClassName('bundle_category_active')) {
        if ($$('div.bundle_category_active').size() > 0) {
            $$('div.bundle_category_active')[0].hide();
            $$('div.bundle_category_active')[0].removeClassName('bundle_category_active') ;
        }
        $('category_bundle_'+id).addClassName('bundle_category_active');
        Effect.Appear('category_bundle_'+id, { duration: 0.3 });
    }
}

function user_profile_edit_save_categories() {
    new Ajax.Request(
        '/download/update_ratings', 
        {
            asynchronous:true, 
            evalScripts:false, 
            parameters:Form.serialize($('ajax'))
        });
}

function download_save_settings() {
    new Ajax.Request(
        '/download/update_data', 
        {
            asynchronous:true, 
            evalScripts:false, 
            parameters:Form.serialize($('ajax'))
        });
}

function bundlePopup(id){
    var position = $j('#'+id).position();
    $j("#bundlepopup").css({
        "display":"block",
        "left":position.left,
        "top":position.top
    });
}