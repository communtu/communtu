# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

class UserObserver < ActiveRecord::Observer
  def after_create(user)
    if user.email[-11..-1]!="example.org"
      UserMailer.deliver_signup_notification(user)
    end  
  end

  def after_save(user)
  
    UserMailer.deliver_activation(user) if user.pending?
    UserMailer.deliver_forgot_password(user) if user.recently_forgot_password?
    UserMailer.deliver_reset_password(user) if user.recently_reset_password?
  end
end
