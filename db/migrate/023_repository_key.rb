class RepositoryKey < ActiveRecord::Migration
  def self.up
    add_column :repositories, :gpgkey, :string, :null => nil
  end
    
  def self.down
    remove_column :repositories, :gpgkey
  end
end

