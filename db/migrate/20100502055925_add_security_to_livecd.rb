class AddSecurityToLivecd < ActiveRecord::Migration
  def self.up
    add_column :livecds, :license_type, :integer
    add_column :livecds, :security_type, :integer
    Livecd.all.each do |cd|
      u = cd.users[0]
      cd.license_type = u.license
      cd.security_type = u.security
      cd.save
      system "mv #{cd.filename_old} #{cd.filename}"
    end
  end

  def self.down
    remove_column :livecds, :security_type
    remove_column :livecds, :license_type
  end
end
