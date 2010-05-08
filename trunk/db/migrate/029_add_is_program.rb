class AddIsProgram < ActiveRecord::Migration
  def self.up
    add_column :base_packages, :is_program, :boolean
end
    
  def self.down
    remove_column :base_packages, :is_program
  end
end
