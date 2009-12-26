#!/usr/bin/ruby
#shows the percent of users which come back after a day
b = "2009-11-01"
e = "2009-12-01"
#e = (ARGV[1])
u = User.find(:all, :conditions => "created_at > '#{b} 00:00:00' and created_at < '#{e} 00:00:00'")
counter = 0
u.each do |u|
s = Userlog.find(:first, :order => "created_at DESC", :conditions => {:user_id => u.id})
if s != nil
diff = s.created_at - u.created_at
if diff > 86400
counter = counter+1
end
end
end
f = User.find(:all, :conditions => "created_at > '#{b} 00:00:00' and created_at < '#{e} 00:00:00'").length
counter.to_f*100/f.to_f

