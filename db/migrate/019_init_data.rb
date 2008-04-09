class InitData < ActiveRecord::Migration
  def self.up
    user
    categories
  end
 
  def self.down
    Role.find_by_rolename('administrator').destroy   
    Role.find_by_rolename('priviliged').destroy;
    Role.find_by_rolename('user').destroy
    User.find_by_login('admin').destroy   
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
    category.name        = "Büro"
    category.description = "Programme, die zum Büroalltag ben�tigt werden"
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
    category.description = "Software für Dichter und Denker..."
    category.parent_id   = 1
    category.save
    
    category = Category.new
    category.name        = "Spiele"
    category.description = "Für die Entspannung zwischendurch"
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
    Role.create(:rolename => 'priviliged')
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
  end
  
end
