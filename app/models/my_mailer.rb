class MyMailer < ActionMailer::Base
  def mail(user)
    @from = 'info@communtu.de'
    @recipients = 'info@communtu.de'
    @sent_on = Time.now
	  @body["title"] = 'Deine Frage bei Communtu'
  	#@body["email"] = 'info@toddy-franz.de'
   #	@body["message"] = @form_name
    @headers = {}
    
#    @recipients = params[:name]
#    @subject = "Hi #{recipient}"
  #  @body(:recipient => recipient)
  end
  #   @formular.name = params[:form][:name]
   #  @formular.frage = params[:form][:frage]
    # @from = 'info@communtu.de'
     #@recipients = 'info@communtu.de'
     #@subject = "Hi #{@formular.name}"
    # @body(@recipients => recipient)
  #end  
end
