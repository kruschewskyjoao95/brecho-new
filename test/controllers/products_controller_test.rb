require "test_helper"

class ProductsControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Limpa produtos existentes se necessário, ou apenas usa fixtures.
    # Mas como criamos produtos específicos, vamos criá-los no setup para testar com dados controlados:
    Product.destroy_all
    
    @p1 = Product.create!(
      name: "Vestido Floral Lindo",
      description: "Lindo vestido com estampas florais para o verão.",
      price_cents: 12000,
      category: "Vestidos",
      sizes: "P, M",
      colors: "Vermelho, Branco",
      brand: "Farm",
      condition: "new_with_tags",
      stock: 1,
      active: true
    )

    @p2 = Product.create!(
      name: "Calça Jeans Skinny",
      description: "Calça jeans clássica e muito confortável.",
      price_cents: 8000,
      category: "Calças",
      sizes: "M, G",
      colors: "Azul",
      brand: "Zara",
      condition: "gently_used",
      stock: 1,
      active: true
    )
  end

  test "should get index with all active products" do
    get products_path
    assert_response :success
    assert_select "h3.product-title", 2
  end

  test "should filter by category" do
    get products_path, params: { category: "Calças" }
    assert_response :success
    assert_match "Calça Jeans Skinny", response.body
    assert_no_match "Vestido Floral Lindo", response.body
  end

  test "should filter by query search" do
    get products_path, params: { query: "Floral" }
    assert_response :success
    assert_match "Vestido Floral Lindo", response.body
    assert_no_match "Calça Jeans Skinny", response.body
  end

  test "should filter by brand" do
    get products_path, params: { brand: "Zara" }
    assert_response :success
    assert_match "Calça Jeans Skinny", response.body
    assert_no_match "Vestido Floral Lindo", response.body
  end

  test "should filter by condition" do
    get products_path, params: { condition: "new_with_tags" }
    assert_response :success
    assert_match "Vestido Floral Lindo", response.body
    assert_no_match "Calça Jeans Skinny", response.body
  end

  test "should filter by size" do
    get products_path, params: { size: "P" }
    assert_response :success
    assert_match "Vestido Floral Lindo", response.body
    assert_no_match "Calça Jeans Skinny", response.body
  end
end
