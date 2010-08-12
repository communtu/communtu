# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

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
  def repo(form_name, form_frage, current_user)
    @form_name = form_name
    @form_frage = form_frage
    @recipients = 'at@bremer-commune.de'
    @from = current_user.email
    @sent_on = Time.now
    @subject = I18n.t(:model_mailer_5)
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

  def livecd(user,iso)
    @body[:url]  = iso
    @recipients  = "#{user.email}"
    @from        = "info@communtu.org"
    @subject     = I18n.t(:livecd_email)
    @sent_on     = Time.now
    @body[:user] = user
    @headers = {}
  end

  def livecd_failed(user,name)
    @cdname      = name
    @recipients  = "#{user.email}"
    @from        = "info@communtu.org"
    @subject     = I18n.t(:livecd_email_failed)
    @sent_on     = Time.now
    @body[:user] = user
    @headers = {}
  end

end
