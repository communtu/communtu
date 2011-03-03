class AddPublishedToLivecds < ActiveRecord::Migration
  def self.up
    add_column :livecds, :published, :boolean, :default => false
    Livecd.all.each do |cd|
      cd.published = cd.bundles_published?
      cd.save
    end  
  end

  def self.down
    remove_column :livecds, :published
  end
end
