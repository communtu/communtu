class AddPackageUrl < ActiveRecord::Migration
  def self.up
      add_column :base_packages, :urls, :text
      readwiki
  end

  def self.down
      remove_column :base_packages, :urls
  end
  
  private
  
  def self.readwiki
    File.open("db/migrate/wiki-info") do |f|
      while !f.eof do
        plist = []
        while (p = f.gets.chop) != "----" && !f.eof do
          plist << p
        end
        if !plist.empty? then
          puts plist[0]
          weblink = "http://wiki.ubuntuusers.de/"+plist[0]
          plist[1,plist.length-1].each do |pname|
            BasePackage.find(:all, :conditions => ["name = ?",pname]).each do |package|
              if package.urls.nil? then package.urls = "" end
              if !package.urls.empty? then package.urls << " " end
              package.urls << weblink  
              package.save
            end
          end
        end
      end
    end
  end
end
