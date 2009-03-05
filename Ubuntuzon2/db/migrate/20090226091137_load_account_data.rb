require 'active_record/fixtures'
class LoadAccountData < ActiveRecord::Migration
  def self.up
    Account.delete_all
    directory = File.join(File.dirname(__FILE__), "data")
    Fixtures.create_fixtures(directory, "accounts")
  end

  def self.down
    Account.delete_all
  end
end
