require File.dirname(__FILE__) + '/../test_helper'
require 'accounts_controller'

# Re-raise errors caught by the controller.
class AccountsController; def rescue_action(e) raise e end; end

class AccountsControllerTest < Test::Unit::TestCase
  # Be sure to include AuthenticatedTestHelper in test/test_helper.rb instead
  # Then, you can remove it from this and the units test.
  include AuthenticatedTestHelper

  fixtures :accounts

  def setup
    @controller = AccountsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_allow_signup
    assert_difference 'Account.count' do
      create_account
      assert_response :redirect
    end
  end

  def test_should_require_login_on_signup
    assert_no_difference 'Account.count' do
      create_account(:login => nil)
      assert assigns(:account).errors.on(:login)
      assert_response :success
    end
  end

  def test_should_require_password_on_signup
    assert_no_difference 'Account.count' do
      create_account(:password => nil)
      assert assigns(:account).errors.on(:password)
      assert_response :success
    end
  end

  def test_should_require_password_confirmation_on_signup
    assert_no_difference 'Account.count' do
      create_account(:password_confirmation => nil)
      assert assigns(:account).errors.on(:password_confirmation)
      assert_response :success
    end
  end

  def test_should_require_email_on_signup
    assert_no_difference 'Account.count' do
      create_account(:email => nil)
      assert assigns(:account).errors.on(:email)
      assert_response :success
    end
  end
  

  

  protected
    def create_account(options = {})
      post :create, :account => { :login => 'quire', :email => 'quire@example.com',
        :password => 'quire', :password_confirmation => 'quire' }.merge(options)
    end
end
