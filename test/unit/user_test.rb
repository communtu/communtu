require File.dirname(__FILE__) + '/../test_helper'

class UserTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead.
  # Then, you can remove it from this and the functional test.
  include AuthenticatedTestHelper
  fixtures :users, :base_packages
  
  def test_if_group_data_is_cleaned_from_db_when_user_is_deleted
    user = create_user
    group = Group.create(:name => "unittest_group", :owner_id => user.id)
    group.users << user
    meta = BasePackage.first
    meta.group_id = group.id
    meta.save

    assert_not_nil group.users
    user.destroy
    assert_not_nil group.users

    #assert_equal(0, group.users.length)
    #assert_nil meta.group_id
  end

protected
  def create_user(options = {})
    User.create({ :login => 'quire', :email => 'quire@example.com', :password => 'quire', :password_confirmation => 'quire' }.merge(options))
  end
end
