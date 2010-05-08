class AddCodeToTranslation < ActiveRecord::Migration
  def self.up
    add_column :translations, :language_code, :string
  end
        
  def self.down
    remove_column :translations, :language_code
  end
end
                
                