require File.dirname(__FILE__) + '/../test_helper'

class TempMetapackagesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:temp_metapackages)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_temp_metapackages
    assert_difference('TempMetapackages.count') do
      post :create, :temp_metapackages => { }
    end

    assert_redirected_to temp_metapackages_path(assigns(:temp_metapackages))
  end

  def test_should_show_temp_metapackages
    get :show, :id => temp_metapackages(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => temp_metapackages(:one).id
    assert_response :success
  end

  def test_should_update_temp_metapackages
    put :update, :id => temp_metapackages(:one).id, :temp_metapackages => { }
    assert_redirected_to temp_metapackages_path(assigns(:temp_metapackages))
  end

  def test_should_destroy_temp_metapackages
    assert_difference('TempMetapackages.count', -1) do
      delete :destroy, :id => temp_metapackages(:one).id
    end

    assert_redirected_to temp_metapackages_path
  end
end
