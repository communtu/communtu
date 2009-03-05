class UpdateAccount < ActiveRecord::Migration
  def self.up
    rename_column "configurations", "user_id", "account_id"
    rename_column "uploads", "user_id", "account_id"
    remove_column :accounts, :user_id
  end

  def self.down
    rename_column "configurations", "account_id", "user_id"
    rename_column "uploads", "account_id", "user_id"
    add_column :accounts, :user_id, :integer
  end
end
