# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/

@toggleCd =(id) ->
	if $j("#"+id).css("opacity") is "1"
		$j("#"+id).css("opacity",0.1)
		$j("#"+id+"check").attr("checked",false)
	else
		$j("#"+id).css("opacity",1)
		$j("#"+id+"check").attr("checked",true)