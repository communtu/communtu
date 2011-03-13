# (c) 2008-2011 by Allgemeinbildung e.V., Bremen, Germany
# This file is part of Communtu.

# Communtu is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# Communtu is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero Public License for more details.

# You should have received a copy of the GNU Affero Public License
# along with Communtu.  If not, see <http://www.gnu.org/licenses/>.

# mail messages sent by Communtu

class MyMailer < ActionMailer::Base
  def mail(form_name, form_frage, current_user)
    @form_name = form_name
    @form_frage = form_frage
    @recipients = 'at@bremer-commune.de'
    @from = current_user.email
    @sent_on = Time.now
    @subject = "[Communtu] " + I18n.t(:model_mailer_1)
    @body = {:title => @form_name, :comment => @form_frage}
    @headers = {}
  end
  def repo(form_name, form_frage, current_user)
    @form_name = form_name
    @form_frage = form_frage
    @recipients = 'at@bremer-commune.de'
    @from = current_user.email
    @sent_on = Time.now
    @subject = "[Communtu] " + I18n.t(:model_mailer_5)
    @body = {:title => @form_name, :comment => @form_frage}
    @headers = {}
  end                              
  def mailerror(form_email)
    @form_email = form_email
    @recipients = 'at@bremer-commune.de'
    @from = @form_email
    @sent_on = Time.now
    @subject = "[Communtu] " + I18n.t(:model_mailer_1)
   # @body = {:title => @form_name, :comment => @form_frage}
    @headers = {}
  end

  def livecd(user,iso)
    @body[:url]  = iso
    @recipients  = "#{user.email}"
    @from        = "info@communtu.org"
    @subject     = "[Communtu] " + I18n.t(:livecd_email)
    @sent_on     = Time.now
    @body[:user] = user
    @headers = {}
  end

  def livecd_failed(user,name)
    @cdname      = name
    @recipients  = "#{user.email}, technik@communtu.org"
    @from        = "info@communtu.org"
    @subject     = "[Communtu] " + I18n.t(:livecd_email_failed)
    @sent_on     = Time.now
    @body[:user] = user
    @headers = {}
  end

  def signup_notification(user)
    setup_email(user)
    @subject    = "[Communtu] " + I18n.t(:model_mailer_0)
    @body[:url]  = "http://www.communtu.de"
  end

  def activation(user)
    setup_email(user)
    @subject    = "[Communtu] " + I18n.t(:model_mailer_2)
    @body[:url]  = "http://www.communtu.de"
  end

  def forgot_password(user)
    setup_email(user)
    @subject    = "[Communtu] " + I18n.t(:model_mailer_3)
    @body[:url]  = "http://localhost:3000/reset_password/#{user.password_reset_code}"
  end

  def reset_password(user)
    setup_email(user)
    @subject    = "[Communtu] " + I18n.t(:model_mailer_4)
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
