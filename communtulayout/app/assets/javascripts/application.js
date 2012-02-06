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
		$("#start" + i).animate({opacity:1},3000);
		document.getElementById("start"+i).style.display="block";
		
		$("#start" + (i+2)%3).animate({opacity:0},3000);
		s="document.getElementById('start"+(i+2)%3+"').style.display='none'";
		window.setTimeout(s,3000);
		i += 1;
		if(i>2){
			i=0;
	    }
		window.setTimeout("rotate("+i+")",10000);  
} 

function toggle_visibility(id) {
       var e = document.getElementById(id);
       if(e.style.display == 'block')
          e.style.display = 'none';
       else
          e.style.display = 'block';
    }
