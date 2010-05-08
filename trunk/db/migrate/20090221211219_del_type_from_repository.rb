class DelTypeFromRepository < ActiveRecord::Migration
  def self.up
    remove_column :repositories, :type
  end

  def self.down
    add_column :repositories, :type, :text
  end
end
