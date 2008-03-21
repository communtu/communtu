class InitData < ActiveRecord::Migration
  def self.up
    user
    categories
    distributions
   # create_meta
  end
 
  def self.down
    Role.find_by_rolename('administrator').destroy   
    Role.find_by_rolename('user').destroy
    User.find_by_login('admin').destroy   
    User.find_by_login('user').destroy
  end
  
  private
  
  def self.categories
      category = Category.new
    category.name        = "Root"
    category.description = "Root category"
    category.parent_id   = 0
    category.save
        
    category = Category.new
    category.name        = "Grafisches Design und Layout"
    category.description = "Aktivitaeten rund um Grafik"
    category.parent_id   = 1
    category.save
        
    category = Category.new
    category.name        = "Audio"
    category.description = "Alles rund um Musik"
    category.parent_id   = 1
    category.save
        
      category = Category.new
      category.name        = "Musik Hoeren"
      category.description = "Musik hoeren"
      category.parent_id   = 3
      category.save
        
      category = Category.new
      category.name        = "Musik Machen"
      category.description = "Musik machen"
      category.parent_id   = 3
      category.save
          
    category = Category.new
    category.name        = "Film"
    category.description = "Alles rund um Filme"
    category.parent_id   = 1
    category.save
        
      category = Category.new
      category.name        = "Filme Gucken"
      category.description = "Filme gucken"
      category.parent_id   = 6
      category.save
        
      category = Category.new
      category.name        = "Filme Machen"
      category.description = "Filme machen"
      category.parent_id   = 6
      category.save
          
    category = Category.new
    category.name        = "Programmieren"
    category.description = "Programme schreiben"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "B�ro"
    category.description = "Programme, die zum B�roalltag ben�tigt werden"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Fremdsprachen"
    category.description = "Lernprogramme, Dictionarys und andere Software, die mit Sprachen zu tun hat"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Naturwissenschaften"
    category.description = "Physik, Chemie und Biologie"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Geisteswissenschaften"
    category.description = "Software f�r Dichter und Denker..."
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Spiele"
    category.description = "F�r die Entspannung zwischendurch"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Webdesign"
    category.description = "Software, die f�r die Erstellung einer Internetpr�senz gebraucht wird"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Planen und Organisieren"
    category.description = "Projektmanagement? Verwaltung? Terminplanung? Hier sind sie richtig"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Kommunikation"
    category.description = "Chatten, Telefonieren & Co"
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Barrierefreiheit"
    category.description = ""
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "CD/DVD"
    category.description = ""
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Administration"
    category.description = ""
    category.parent_id   = 1
    category.save
  end
  
  def self.user
    #Make sure the role migration file was generated first    
    Role.create(:rolename => 'administrator')    
    Role.create(:rolename => 'user')
    #Then, add default admin user
    #Be sure change the password later or in this migration file
    user = User.new
    user.login = "admin"
    user.email = "info@yourapplication.com"
    user.password = "admin"
    user.password_confirmation = "admin"
    user.save(false)
    user.send(:activate!)
    role = Role.find_by_rolename('administrator')
    user = User.find_by_login('admin')
    permission = Permission.new
    permission.role = role
    permission.user = user
    permission.save(false)
    
    #adding normal user
    user = User.new
    user.login = "user"
    user.email = "info@yourapplication.com"
    user.password = "user"
    user.password_confirmation = "user"
    user.save(false)
    user.send(:activate!)
    role = Role.find_by_rolename('user')
    user = User.find_by_login('user')
    permission = Permission.new
    permission.role = role
    permission.user = user
    permission.save(false)
  end
  
  def self.distributions
    d = Distribution.new({ :name => "gutsy_test", :description => "a test distribution"})
    d.save(false)

    d = Repository.new({ :distribution_id => 1, :license_type => 0, :type => "deb",\
      :url => "deb http://de.archive.ubuntu.com/ubuntu/ gutsy",\
      :security_type => 0,\
      :subtype => "main" })
      
    d.save(false)
    Package.import_source d
    
    d = Repository.new({ :distribution_id => 1, :license_type => 1, :type => "deb",\
      :url => "deb http://de.archive.ubuntu.com/ubuntu/ gutsy",\
      :security_type => 0,\
      :subtype => "restricted" })
      
    d.save(false)
    Package.import_source d
    
    d = Repository.new({ :distribution_id => 1, :license_type => 1, :type => "deb",\
      :url => "deb http://de.archive.ubuntu.com/ubuntu/ gutsy",\
      :security_type => 0,\
      :subtype => "universe" })
      
    d.save(false)
    Package.import_source d
    
    d = Repository.new({ :distribution_id => 1, :license_type => 1, :type => "deb",\
      :url => "deb http://download.skype.com/linux/repos/debian/ stable",\
      :security_type => 2,\
      :subtype => "non-free" })
      
    d.save(false)
    
    Package.import_source d
    
    #d = Metapackage.new ({ :name => "graphic_editors", :license_type => 0,
    #  :description => "This package contains some of the most used editors for graphics, like Gimp + Inkscape", :category_id => 2, :distribution_id => 1,\
    #  :rating => 1})
    #d.save false
    #5.times do |i|
    #  d = Metacontent.new ( :metapackage_id => 1, :package_id => (i+1))
    #  d.save
    #end
    #d = Metapackage.new ({ :name => "ruby_developer_package", :license_type => 0,
    #  :description => "This package should contain eveerything you need, to develop ruby applications",\
    #  :category_id => 9, :distribution_id => 1, :rating => 1})
    #d.save false
    #5.times do |i|
    #  d = Metacontent.new ( :metapackage_id => 2, :package_id => (i+1))
     # d.save
    #end
    #d = TempMetapackage.new ({ :name => "ruby_developer_package_better", :license_type => 0,
    #  :description => "Ubuntus gem has problems with some gems. Take this package, and install gems from http://www.rubygems.org/", :distribution_id => 1,\
    #  :rating => 1, :user_id => 2, :is_saved => 1})
    #d.save false
    
    #id = d.id 
    #5.times do |i|
    #  d = TempMetacontent.new ( :temp_metapackage_id => 1, :package_id => (i+1))
    #  d.save
    #end
    
    #d = Comment.new({ :metapackage_id => 2, :temp_metapackage_id => 1, :user_id => 2,\
    #  :comment => "Ubuntu's version seems to be buggy, install this package, and follow the instructions..."})
    #d.save
  end
  
  def self.create_meta
    packages = { "Grafik-Bearbeitung"  => { "Description" => "Alles für Bildbearbeitung, inklusive Vektorgrafik.",\
        "Packages" => ["showfoto", "gimp", "inkscape", "imagemagick",\
        "Xsane", "gqview"], "Cat" => 2, "license" => 0 },\
      "CD/DVD brennen" => { "Description" => "K3b beherrscht das Brennen aller gängigen Formate und bietet einen leichten Einsteig für Anfänger",\
        "Packages" => ["k3b", "libk3b2", "libk3b2-mp3", "normalize-audio"], "Cat" => 19, "license" => 0 },\
      "Systemwerkzeuge" => { "Description" => "Alles was der Admin braucht...",\
        "Packages" => ["openssh-client", "openssh-server", "gparted", "menu-xdg",\
        "alien"], "Cat" => 20, "license" => 0 },
       "P2P-Netzwerke & Filesharing" => { "Description" => "In diesem Paket befinden sich mit aMule und azureus die meistgenutzesten P2P-Programme im Linux Bereich",\
        "Packages" => ["openssh-client", "openssh-server", "gparted", "menu-xdg",\
        "alien"], "Cat" => 20, "license" => 0 }\
    }  
    
    install_meta packages
  end
  
  def self.install_meta packages
    packages.each do |key,i|
      
      d = Metapackage.new ({ :name => key, :license_type => i["license"],
       :description => i["Description"],\
       :category_id => i["Cat"], :distribution_id => 1, :rating => 0})
    
      d.save
      
      i["Packages"].each do |p|
        
        id = Package.find_by_name(p)
        
        if not id.nil?
          s = Metacontent.new({:metapackage_id => d.id, :package_id => Package.find_by_name}, :is_meta => false)  
        else
          d.description += "<br/> " + p;
        end
      end
      
      d.save
    end
  end
end
