class AddPublishedToLivecds < ActiveRecord::Migration
  def self.up
    add_column :livecds, :published, :boolean, :default => false
  end

  def self.down
    remove_column :livecds, :published
  end
end
