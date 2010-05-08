class CreateLivecdUsers < ActiveRecord::Migration
  def self.up
    create_table :livecd_users do |t|
      t.integer :livecd_id
      t.integer :user_id

      t.timestamps
    end
    Livecd.all.each do |cd|
      LivecdUser.create({:livecd_id=>cd.id, :user_id=>cd.user_id})
    end
    remove_column :livecds, :user_id
    add_column :livecds, :first_try, :boolean, :default => true
  end

  def self.down
    drop_table :livecd_users
    add_column :livecds, :user_id, :integer
    remove_column :livecds, :first_try
  end
end
