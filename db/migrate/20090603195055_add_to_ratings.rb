class AddToRatings < ActiveRecord::Migration
  def self.up
     add_column :ratings, :comment, :text
  end
 
  def self.down
     remove_column :ratings, :comment
  end
end
