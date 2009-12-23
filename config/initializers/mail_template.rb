# Email settings
#ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.smtp_settings = {
:address => "mail.gmx.net",
:port => 25,
:domain => "mail.gmx.net",
:user_name => "communtu@gmx.de",
:password => "mypass",
:authentication => :login
}
#ActionMailer::Base.sendmail_settings = {
#  :location => "/usr/sbin/sendmail"  
#}
