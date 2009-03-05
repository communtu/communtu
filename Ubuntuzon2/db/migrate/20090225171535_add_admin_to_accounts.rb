class AddAdminToAccounts < ActiveRecord::Migration
    def self.up
      add_column "accounts", "permission", :integer, :default => 1
    end

    def self.down
      remove_column "accounts", "permission"
    end
end
