class MyMailer < ActionMailer::Base
  def mail(form_name, form_frage, current_user)
    @form_name = form_name
    @form_frage = form_frage
    @email_helper = current_user
  #  if @email_helper.nil or @email_helper == ""
  #      @recipients = 'info@communtu.de'
  #      @from = 'info@communtu.de'
  #  else
        @recipients = 'info@communtu.de'
        @from = current_user.email
  #  end
   # @recipients = 'info@communtu.de', current_user.email
   # @from = current_user.email
    @sent_on = Time.now
    @subject = 'Deine Frage bei Communtu'
	 # @body = {:title => 'Deine Frage bei Communtu'}
  	#@body["email"] = 'info@toddy-franz.de'
   #	@body["message"] = @form_name
    @body = {:title => @form_name, :comment => @form_frage}
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
