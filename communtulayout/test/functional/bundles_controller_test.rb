require 'test_helper'

class BundlesControllerTest < ActionController::TestCase
  setup do
    @bundle = bundles(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:bundles)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create bundle" do
    assert_difference('Bundle.count') do
      post :create, :bundle => @bundle.attributes
    end

    assert_redirected_to bundle_path(assigns(:bundle))
  end

  test "should show bundle" do
    get :show, :id => @bundle.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @bundle.to_param
    assert_response :success
  end

  test "should update bundle" do
    put :update, :id => @bundle.to_param, :bundle => @bundle.attributes
    assert_redirected_to bundle_path(assigns(:bundle))
  end

  test "should destroy bundle" do
    assert_difference('Bundle.count', -1) do
      delete :destroy, :id => @bundle.to_param
    end

    assert_redirected_to bundles_path
  end
end
