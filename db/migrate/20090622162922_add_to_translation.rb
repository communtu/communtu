class AddToTranslation < ActiveRecord::Migration
  def self.up
    add_column :translations, :translatable_id, :integer
  end
        
  def self.down
    remove_column :translations, :translatable_id
  end
end
                
                