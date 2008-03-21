require File.dirname(__FILE__) + '/../test_helper'

class PacketsControllerTest < ActionController::TestCase
  def test_should_get_index
    get :index
    assert_response :success
    assert_not_nil assigns(:packets)
  end

  def test_should_get_new
    get :new
    assert_response :success
  end

  def test_should_create_packet
    assert_difference('Packet.count') do
      post :create, :packet => { }
    end

    assert_redirected_to packet_path(assigns(:packet))
  end

  def test_should_show_packet
    get :show, :id => packets(:one).id
    assert_response :success
  end

  def test_should_get_edit
    get :edit, :id => packets(:one).id
    assert_response :success
  end

  def test_should_update_packet
    put :update, :id => packets(:one).id, :packet => { }
    assert_redirected_to packet_path(assigns(:packet))
  end

  def test_should_destroy_packet
    assert_difference('Packet.count', -1) do
      delete :destroy, :id => packets(:one).id
    end

    assert_redirected_to packets_path
  end
end
