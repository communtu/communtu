class AddIdToRating < ActiveRecord::Migration
  def self.up
    add_column :ratings, :comment_tid, :integer
  end

  def self.down
    remove_column :ratings, :comment_tid
  end
end
