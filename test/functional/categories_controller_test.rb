require File.dirname(__FILE__) + '/../test_helper'

class CategoriesControllerTest < ActionController::TestCase
  def test_should_get_index
    login_as(:admin)
    get :index
    assert_response :success
    assert_not_nil assigns(:categories)
  end

  def test_should_get_new
    login_as(:admin)
    get :new
    assert_response :success
  end

  def test_should_create_category
    login_as(:admin)
    assert_difference('Category.count') do
      post :create, :category => { :name =>"test"}
    end

    assert_redirected_to category_path(assigns(:category))
  end

  def test_should_show_category
    login_as(:admin)
    get :show, :id => categories(:one).id
    assert_response :success
  end

  def test_should_get_edit
    login_as(:admin)
    get :edit, :id => categories(:one).id
    assert_response :success
  end

  def test_should_update_category
    login_as(:admin)
    put :update, :id => categories(:one).id, :category => { }
    assert_redirected_to category_path(assigns(:category))
  end

  def test_should_destroy_category
    login_as(:admin)
    assert_difference('Category.count', -1) do
      delete :destroy, :id => categories(:one).id
    end

    assert_redirected_to categories_path
  end
end
