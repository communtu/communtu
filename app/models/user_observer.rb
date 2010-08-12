# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

# signup with email notification; currently not used

class UserObserver < ActiveRecord::Observer
  def after_create(user)
    if user.email[-11..-1]!="example.org"
      MyMailer.deliver_signup_notification(user)
    end  
  end

  def after_save(user)
  
    MyMailer.deliver_activation(user) if user.pending?
    MyMailer.deliver_forgot_password(user) if user.recently_forgot_password?
    MyMailer.deliver_reset_password(user) if user.recently_reset_password?
  end
end
