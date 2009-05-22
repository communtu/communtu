class CreateInboxForUsersWhoDontHaveOne < ActiveRecord::Migration
  def self.up
    User.find(:all).each do |user|
      user.folders.create!(:name => "Inbox") if user.inbox.nil?
    end
  end

  def self.down
    # Hier gibt es kein zurück.
    # raise ActiveRecord::IrreversibleMigration
  end
end
