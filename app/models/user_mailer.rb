class UserMailer < ActionMailer::Base
  def signup_notification(user)
    setup_email(user)
    @subject    = _('Herzlich Willkommen bei Communtu')  
    @body[:url]  = "http://www.communtu.de"
  end
  
 def contact_us(user)  
    @body[:url]  = "http://www.communtu.de"  
    @recipients  = "info@toddy-franz.de"
    @from        = "info@toddy-franz.de"
    @from        = "#{user.email}"
    @subject     = _('Anfrage per Formular')
    @sent_on     = Time.now
    @body[:user] = user
  end
  
  def activation(user)
    setup_email(user)
    @subject    = _('Dein Benutzerkonto wurde aktiviert.')
    @body[:url]  = "http://www.communtu.de"
  end
  
  def forgot_password(user)
    setup_email(user)
    @subject    = _('Du hast angefordert, dein Kennwort zurückzusetzen')
    @body[:url]  = "http://localhost:3000/reset_password/#{user.password_reset_code}"
  end
 
  def reset_password(user)
    setup_email(user)
    @subject    = _('Dein Passwort wurde zurueckgesetzt..')
  end
  
  protected
    def setup_email(user)
      @recipients  = "#{user.email}"
      @from        = "info@communtu.de"
      @subject     = ""
      @sent_on     = Time.now
      @body[:user] = user
    end
end
