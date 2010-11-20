require File.dirname(__FILE__) + '/../test_helper'

class MetapackagesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:metapackages)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_metapackage
    login_as(:admin)
    assert_difference('Metapackage.count') do
      post :create, :metapackage => {:name=>"fancy name not existing so far", 
                      :category_id => Category.first.object_id, :version=>"0.1", :license_type => 0,
                      :description=>"Meine unverzichtbaren Programme und Helferlein für den Büroalltag"}
    end

    assert_redirected_to metapackage_path(assigns(:metapackage))
  end

  def test_should_show_metapackage
    get :show, :id => base_packages(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => base_packages(:one).id
    assert_response :success
  end

  def test_should_update_metapackage
    put :update, :id => base_packages(:one).id, :metapackage => { }
    assert_redirected_to metapackage_path(assigns(:metapackage))
  end

  def test_should_destroy_metapackage
    login_as(:admin)
    assert_difference('Metapackage.count', -1) do
      delete :destroy, :id => base_packages(:one).id
    end

    assert_redirected_to metapackages_path
  end
end
