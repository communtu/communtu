# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

@toggle =(id) ->
	if $("#"+id).css("opacity") is "1"
		$("#"+id).css("opacity",0.1)
		$("#"+id+"check").attr("checked",false)
	else
		$("#"+id).css("opacity",1)
		$("#"+id+"check").attr("checked",true)