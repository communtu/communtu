# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    = I18n.t(:model_mailer_0)  
    @body[:url]  = "http://www.communtu.de"
  end

  def activation(user)
    setup_email(user)
    @subject    = I18n.t(:model_mailer_2)
    @body[:url]  = "http://www.communtu.de"
  end
  
  def forgot_password(user)
    setup_email(user)
    @subject    = I18n.t(:model_mailer_3)
    @body[:url]  = "http://localhost:3000/reset_password/#{user.password_reset_code}"
  end
 
  def reset_password(user)
    setup_email(user)
    @subject    = I18n.t(:model_mailer_4)
  end

  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "account@communtu.de"
      @subject     = ""
      @sent_on     = Time.now
      @body[:user] = user
    end
end
