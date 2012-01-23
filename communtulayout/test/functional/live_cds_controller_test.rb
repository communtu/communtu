require 'test_helper'

class LiveCdsControllerTest < ActionController::TestCase
  setup do
    @live_cd = live_cds(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:live_cds)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create live_cd" do
    assert_difference('LiveCd.count') do
      post :create, :live_cd => @live_cd.attributes
    end

    assert_redirected_to live_cd_path(assigns(:live_cd))
  end

  test "should show live_cd" do
    get :show, :id => @live_cd.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @live_cd.to_param
    assert_response :success
  end

  test "should update live_cd" do
    put :update, :id => @live_cd.to_param, :live_cd => @live_cd.attributes
    assert_redirected_to live_cd_path(assigns(:live_cd))
  end

  test "should destroy live_cd" do
    assert_difference('LiveCd.count', -1) do
      delete :destroy, :id => @live_cd.to_param
    end

    assert_redirected_to live_cds_path
  end
end
