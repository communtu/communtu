require 'test_helper'

class DerivativesControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:derivatives)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_derivative
    assert_difference('Derivative.count') do
      post :create, :derivative => { }
    end

    assert_redirected_to derivative_path(assigns(:derivative))
  end

  def test_should_show_derivative
    get :show, :id => derivatives(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => derivatives(:one).id
    assert_response :success
  end

  def test_should_update_derivative
    put :update, :id => derivatives(:one).id, :derivative => { }
    assert_redirected_to derivative_path(assigns(:derivative))
  end

  def test_should_destroy_derivative
    assert_difference('Derivative.count', -1) do
      delete :destroy, :id => derivatives(:one).id
    end

    assert_redirected_to derivatives_path
  end
end
