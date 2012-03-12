# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

imgNumber = 0;
changeIntervalId = null;

changeImg = (a, b) -> 
	$("#changeimg_" + a ).fadeOut "slow"
	$("#changeimg_" + b ).fadeIn "slow", (-> 
		$("#change_tag_" + a ).css "background-color", "rgba(255,225,175,0.7)"
		$("#change_tag_" + a ).hover (->
			$("#change_tag_" + a ).css "background-color", "rgb(255,220,155)"), ->
			$("#change_tag_" + a ).css "background-color", "rgba(255,225,175,0.7)"	
		$("#change_tag_" + b ).css "background-color", "rgb(255,220,155)"
		$("#change_tag_" + b ).hover (->
			$("#change_tag_" + b ).css "background-color", "rgb(255,220,155)"), ->
			$("#change_tag_" + b ).css "background-color", "rgb(255,220,155)"	
		$("#change_circle_" + a ).attr "src", "/assets/circle.png"
		$("#change_circle_" + b ).attr "src", "/assets/circle_active.png"
	)
	imgNumber = b

@changeImgTo = (number) ->
	if imgNumber isnt number
		window.clearInterval changeIntervalId
		changeImg imgNumber, number
		imgNumber = number
		changeIntervalId = window.setInterval (-> changeImg imgNumber, (imgNumber+1)%3) , 5000 
	
	


window.onload = -> 
	changeIntervalId = window.setInterval (-> changeImg imgNumber, (imgNumber+1)%3) , 5000 