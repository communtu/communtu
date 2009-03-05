class AddUserToAccount < ActiveRecord::Migration
  def self.up
    add_column "accounts", "firstname", :string
    add_column "accounts", "lastname", :string
    add_column "accounts", "gender", :integer
    add_column "accounts", "newsletter", :integer
  end

  def self.down
    remove_column "accounts", "firstname"
    remove_column "accounts", "lastname"
    remove_column "accounts", "gender"
    remove_column "accounts", "newsletter"
  end
end
