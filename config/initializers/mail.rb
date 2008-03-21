# Email settings
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.sendmail_settings = {
  :location => "/usr/sbin/sendmail"  
}