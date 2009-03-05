require 'active_record/fixtures'
class LoadWhitelistData < ActiveRecord::Migration
  def self.up
    directory = File.join(File.dirname(__FILE__), "data")
    Fixtures.create_fixtures(directory, "whitelists")
  end

  def self.down
    Whitelist.delete_all
  end
end
