require "test_helper"

class SellersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @seller = users(:one)
    @seller.update!(role: "seller", cep: "01001-000", address_city: "São Paulo", address_state: "SP")
    
    # Criamos um produto ativo para o vendedor
    @product = Product.create!(
      name: "Vestido Teste",
      price_cents: 5000,
      category: "Vestidos",
      stock: 1,
      active: true,
      seller: @seller
    )
    
    @buyer = users(:two)
    @buyer.update!(role: "buyer")
  end

  test "should get seller show page with active products" do
    get seller_path(@seller)
    
    assert_response :success
    assert_select "h1", @seller.name
    assert_select "div.product-card", 1
    assert_match "Vestido Teste", response.body
  end

  test "should redirect to root if user is not a seller" do
    get seller_path(@buyer)
    
    assert_redirected_to root_path
    assert_equal "Vendedor não encontrado.", flash[:alert]
  end
end
