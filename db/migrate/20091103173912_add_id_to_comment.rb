class AddIdToComment < ActiveRecord::Migration
  def self.up
    add_column :comments, :comment_tid, :integer
  end

  def self.down
    remove_column :comments, :comment_tid
  end
end
