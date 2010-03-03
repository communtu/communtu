module GroupsHelper
   def list_members(group)
   list = ""
   group.users.each do |user|
     list << "<p>" << link_to(user.login, user_path(user.id)) << "</p>"
   end
   return list
 end
 
 def list_groups
   list = ""
   Group.all.each do |group|
     list << "<p>" << link_to(group.name, group_path(group.id)) << "</p>"
   end
   return list
 end
end
