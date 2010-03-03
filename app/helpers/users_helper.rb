module UsersHelper
 def count_new_messages
    current_user.received_messages.find(:all, :conditions=>"is_read = false").length
 end
 
 def list_user_groups
   list = ""
   current_user.groups.find(:all).each do |group|
     list << "<p>" << link_to(group.name, group_path(group.id)) << "</p>"
   end
   list << "<p>" << link_to(t(:new_group), new_group_path) << "</p>" 
   return list
 end
 
end