require 'test_helper'

class InfosControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:infos)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create info" do
    assert_difference('Info.count') do
      post :create, :info => { }
    end

    assert_redirected_to info_path(assigns(:info))
  end

  test "should show info" do
    get :show, :id => infos(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => infos(:one).id
    assert_response :success
  end

  test "should update info" do
    put :update, :id => infos(:one).id, :info => { }
    assert_redirected_to info_path(assigns(:info))
  end

  test "should destroy info" do
    assert_difference('Info.count', -1) do
      delete :destroy, :id => infos(:one).id
    end

    assert_redirected_to infos_path
  end
end
