require "test_helper"

class Admin::FinancialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @seller = users(:one)
    @seller.update!(role: "seller")
    
    @buyer = users(:two)
    @buyer.update!(role: "buyer")
  end

  test "should get financial dashboard when logged in as seller" do
    sign_in_as(@seller)
    get admin_financial_path
    
    assert_response :success
    assert_select "h1", "Painel Financeiro"
  end

  test "should redirect to login when unauthenticated" do
    get admin_financial_path
    assert_redirected_to new_session_path
  end

  test "should redirect to root when logged in as buyer" do
    sign_in_as(@buyer)
    get admin_financial_path
    
    assert_redirected_to root_path
    assert_equal "Você não tem permissão para acessar esta área.", flash[:alert]
  end
end
