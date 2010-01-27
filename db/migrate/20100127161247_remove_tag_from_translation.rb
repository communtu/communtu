class RemoveTagFromTranslation < ActiveRecord::Migration
  def self.up
    remove_column :translations, :tag
    remove_column :translations, :language_id
  end

  def self.down
    add_column :translations, :tag, :string
    add_column :translations, :language_id, :integer
  end
end
