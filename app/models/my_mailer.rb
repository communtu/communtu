class MyMailer < ActionMailer::Base
  def mail(form_name, form_frage, current_user)
    @form_name = form_name
    @form_frage = form_frage
    @recipients = 'at@bremer-commune.de'
    @from = current_user.email
    @sent_on = Time.now
    @subject = I18n.t(:model_mailer_1)
    @body = {:title => @form_name, :comment => @form_frage}
    @headers = {}
  end
  def mailerror(form_email)
    @form_email = form_email
    @recipients = 'at@bremer-commune.de'
    @from = @form_email
    @sent_on = Time.now
    @subject = I18n.t(:model_mailer_1)
   # @body = {:title => @form_name, :comment => @form_frage}
    @headers = {}
  end
end
