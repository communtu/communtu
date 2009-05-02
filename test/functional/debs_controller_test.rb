require 'test_helper'

class DebsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:debs)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_deb
    assert_difference('Deb.count') do
      post :create, :deb => { }
    end

    assert_redirected_to deb_path(assigns(:deb))
  end

  def test_should_show_deb
    get :show, :id => debs(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => debs(:one).id
    assert_response :success
  end

  def test_should_update_deb
    put :update, :id => debs(:one).id, :deb => { }
    assert_redirected_to deb_path(assigns(:deb))
  end

  def test_should_destroy_deb
    assert_difference('Deb.count', -1) do
      delete :destroy, :id => debs(:one).id
    end

    assert_redirected_to debs_path
  end
end
