class MyMailer < ActionMailer::Base
  def mail(user)
    @from = 'info@communtu.de'
    
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
