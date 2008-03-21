require File.dirname(__FILE__) + '/../test_helper'

class UserProfilesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:user_profiles)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_user_profile
    assert_difference('UserProfile.count') do
      post :create, :user_profile => { }
    end

    assert_redirected_to user_profile_path(assigns(:user_profile))
  end

  def test_should_show_user_profile
    get :show, :id => user_profiles(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => user_profiles(:one).id
    assert_response :success
  end

  def test_should_update_user_profile
    put :update, :id => user_profiles(:one).id, :user_profile => { }
    assert_redirected_to user_profile_path(assigns(:user_profile))
  end

  def test_should_destroy_user_profile
    assert_difference('UserProfile.count', -1) do
      delete :destroy, :id => user_profiles(:one).id
    end

    assert_redirected_to user_profiles_path
  end
end
