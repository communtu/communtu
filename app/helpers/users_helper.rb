module UsersHelper
 def count_new_messages
    current_user.received_messages.find(:all, :conditions=>"is_read = false").length
  end
end