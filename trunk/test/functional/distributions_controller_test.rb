require File.dirname(__FILE__) + '/../test_helper'

class DistributionsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:distributions)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_distribution
    assert_difference('Distribution.count') do
      post :create, :distribution => { }
    end

    assert_redirected_to distribution_path(assigns(:distribution))
  end

  def test_should_show_distribution
    get :show, :id => distributions(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => distributions(:one).id
    assert_response :success
  end

  def test_should_update_distribution
    put :update, :id => distributions(:one).id, :distribution => { }
    assert_redirected_to distribution_path(assigns(:distribution))
  end

  def test_should_destroy_distribution
    assert_difference('Distribution.count', -1) do
      delete :destroy, :id => distributions(:one).id
    end

    assert_redirected_to distributions_path
  end
end
