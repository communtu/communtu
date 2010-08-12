# (c) 2008-2010 by Verein Allgemeinbildung e.V., Bremen, Germany
# use, modification or distribution only with permission of the copyright holder

module UsersHelper
 def count_new_messages
    current_user.received_messages.find(:all, :conditions=>"is_read = false").length
  end
end