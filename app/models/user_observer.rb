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
