# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

imgNumber = 0;
changeIntervalId = null;

changeImg = (a, b) -> 
	$j("#changeimg_" + a ).fadeOut "slow"
	$j("#changeimg_" + b ).fadeIn "slow", (-> 
		$j("#change_tag_" + a ).css "background-color", "rgba(255,225,175,0.7)"
		$j("#change_tag_" + a ).hover (->
			$j("#change_tag_" + a ).css "background-color", "rgb(255,220,155)"), ->
			$j("#change_tag_" + a ).css "background-color", "rgba(255,225,175,0.7)"	
		$j("#change_tag_" + b ).css "background-color", "rgb(255,220,155)"
		$j("#change_tag_" + b ).hover (->
			$j("#change_tag_" + b ).css "background-color", "rgb(255,220,155)"), ->
			$j("#change_tag_" + b ).css "background-color", "rgb(255,220,155)"	
		$j("#change_circle_" + a ).attr "src", "/assets/circle.png"
		$j("#change_circle_" + b ).attr "src", "/assets/circle_active.png"
	)
	$j("#preview_link" + a).css "background-color", "#e5c5b5"
	$j("#preview_link" + a).css "border-top", "10px #eeeeee solid"
	$j("#preview_link" + a).css "border-bottom", "15px #feb600 solid"
	$j("#preview_link" + b).css "background-color", "#feb600"
	$j("#preview_link" + b).css "border-top", "10px #feb600 solid"
	$j("#preview_link" + b).css "border-bottom", "15px #feb600 solid"
	imgNumber = b

@changeImgTo = (number) ->
	if imgNumber isnt number
		window.clearInterval changeIntervalId
		changeImg imgNumber, number
		imgNumber = number
#		changeIntervalId = window.setInterval (-> changeImg imgNumber, (imgNumber+1)%3) , 10000 
	
	


window.onload = -> 
	changeIntervalId = window.setInterval (-> changeImg imgNumber, (imgNumber+1)%3) , 10000 