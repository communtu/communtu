require 'test_helper'

class PackagesControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:packages)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create package" do
    assert_difference('Package.count') do
      post :create, :package => { }
    end

    assert_redirected_to package_path(assigns(:package))
  end

  test "should show package" do
    get :show, :id => packages(:one).id
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => packages(:one).id
    assert_response :success
  end

  test "should update package" do
    put :update, :id => packages(:one).id, :package => { }
    assert_redirected_to package_path(assigns(:package))
  end

  test "should destroy package" do
    assert_difference('Package.count', -1) do
      delete :destroy, :id => packages(:one).id
    end

    assert_redirected_to packages_path
  end
end
