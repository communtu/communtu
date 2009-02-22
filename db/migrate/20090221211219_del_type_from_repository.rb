class DelTypeFromRepository < ActiveRecord::Migration
  def self.up
    remove_column :repository, :type
  end

  def self.down
    add_column :repository, :type, :text
  end
end
