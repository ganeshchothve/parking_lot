require 'test_helper'

class ChannelPartnersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @channel_partner = channel_partners(:one)
  end

  test "should get index" do
    get channel_partners_url
    assert_response :success
  end

  test "should get new" do
    get new_channel_partner_url
    assert_response :success
  end

  test "should create channel_partner" do
    assert_difference('ChannelPartner.count') do
      post channel_partners_url, params: { channel_partner: { email: @channel_partner.email, location: @channel_partner.location, name: @channel_partner.name, phone: @channel_partner.phone, rera_id: @channel_partner.rera_id, string: @channel_partner.string } }
    end

    assert_redirected_to channel_partner_url(ChannelPartner.last)
  end

  test "should show channel_partner" do
    get channel_partner_url(@channel_partner)
    assert_response :success
  end

  test "should get edit" do
    get edit_channel_partner_url(@channel_partner)
    assert_response :success
  end

  test "should update channel_partner" do
    patch channel_partner_url(@channel_partner), params: { channel_partner: { email: @channel_partner.email, location: @channel_partner.location, name: @channel_partner.name, phone: @channel_partner.phone, rera_id: @channel_partner.rera_id, string: @channel_partner.string } }
    assert_redirected_to channel_partner_url(@channel_partner)
  end

  test "should destroy channel_partner" do
    assert_difference('ChannelPartner.count', -1) do
      delete channel_partner_url(@channel_partner)
    end

    assert_redirected_to channel_partners_url
  end
end
