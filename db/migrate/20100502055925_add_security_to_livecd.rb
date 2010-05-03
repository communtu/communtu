class Livecd
      # full version of liveCD, made from derivative, distribution and architecture
  def fullversion_old
    self.derivative.name.downcase+"-"+self.distribution.name.gsub(/[a-zA-Z ]/,'')+"-desktop-"+self.architecture.name
  end

  # unique name of liveCD
  def fullname_old
    "#{self.name}-#{self.fullversion_old}"
  end

  # filename of LiveCD in the file system
  def filename_old
    "#{RAILS_ROOT}/public/isos/#{self.fullname_old}.iso"
  end
end

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
