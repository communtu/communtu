// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

function rotate(i){
		$("#start" + i).fadeIn(3000);
		$("#start" + (i+2)%3).fadeOut(3000);
		i = (i+1)%3;
		window.setTimeout("rotate("+i+")",10000);  
} 
	
function showImage(id){
	var i=0;
	for(i=0;i<3;i++)
	{
		if(i==id) 
     	  $("#start" + i).fadeIn(500);
		else  
     	  $("#start" + i).fadeOut(500);
	}	  
}
