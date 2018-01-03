require 'test_helper'

class UserKycsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_kyc = user_kycs(:one)
  end

  test "should get index" do
    get user_kycs_url
    assert_response :success
  end

  test "should get new" do
    get new_user_kyc_url
    assert_response :success
  end

  test "should create user_kyc" do
    assert_difference('UserKyc.count') do
      post user_kycs_url, params: { user_kyc: {  } }
    end

    assert_redirected_to user_kyc_url(UserKyc.last)
  end

  test "should show user_kyc" do
    get user_kyc_url(@user_kyc)
    assert_response :success
  end

  test "should get edit" do
    get edit_user_kyc_url(@user_kyc)
    assert_response :success
  end

  test "should update user_kyc" do
    patch user_kyc_url(@user_kyc), params: { user_kyc: {  } }
    assert_redirected_to user_kyc_url(@user_kyc)
  end

  test "should destroy user_kyc" do
    assert_difference('UserKyc.count', -1) do
      delete user_kyc_url(@user_kyc)
    end

    assert_redirected_to user_kycs_url
  end
end
