class CreateTranslations < ActiveRecord::Migration
  def self.up
    create_table :translations do |t|
      t.integer :language_id
      t.string :tag
      t.text :contents
      t.timestamps
    end
    
    create_languages

  end

  def self.down
    drop_table :translations
  end

  
  def self.create_languages
    en = Language.create(:name => "english", :country_code => "en")
    de = Language.create(:name => "deutsch", :country_code => "de")
    fr = Language.create(:name => "francais", :country_code => "fr")
    nl = Language.create(:name => "nederlands", :country_code => "nl")
    Translation.create(:language_id => en, :tag => "welcome", :contents => "This is the Communtu home page. Please press [Sign up] to create a new user or [log in]")
    Translation.create(:language_id => de, :tag => "edit_proile_start", :contents => "Hier koennen Sie ihr Benutzerprofil editieren. Die Information, die Sie hier eingeben, verwendet das System, um Ihnen eine maßgeschneiderte Installation vorzuschlagen.")
    Translation.create(:language_id => de, :tag => "edit_proile_start", :contents => "Here you can edit your user profile. The information you enter here will be used for suggesting an installation satisfying your needs.")
    Translation.create(:language_id => en, :tag => "login_message", :contents => "Login with User ID and Password:")
    Translation.create(:language_id => de, :tag => "login_message", :contents => "Anmeldung mit Nutzerkennung und Passwort:")
  end   
end
