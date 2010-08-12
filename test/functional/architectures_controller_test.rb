require File.dirname(__FILE__) + '/../test_helper'

class ArchitecturesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:architectures)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create architecture" do
    assert_difference('Architecture.count') do
      post :create, :architecture => { }
    end

    assert_redirected_to architecture_path(assigns(:architecture))
  end

  test "should show architecture" do
    get :show, :id => architectures(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => architectures(:one).id
    assert_response :success
  end

  test "should update architecture" do
    put :update, :id => architectures(:one).id, :architecture => { }
    assert_redirected_to architecture_path(assigns(:architecture))
  end

  test "should destroy architecture" do
    assert_difference('Architecture.count', -1) do
      delete :destroy, :id => architectures(:one).id
    end

    assert_redirected_to architectures_path
  end
end
