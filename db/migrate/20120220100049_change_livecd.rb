class ChangeLivecd < ActiveRecord::Migration
  def self.up
    change_column(:livecds, :log, :mediumtext)
  end

  def self.down
  end
end
