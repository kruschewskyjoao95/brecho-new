require "test_helper"

class FavoritesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @product = Product.create!(
      name: "Vestido Floral",
      price_cents: 8990,
      category: "Vestidos",
      stock: 1,
      active: true
    )
  end

  test "should redirect to login if accessing favorites index unauthenticated" do
    get favorites_path
    assert_redirected_to new_session_path
  end

  test "should get favorites index when authenticated" do
    sign_in_as(@user)
    @user.favorites.create!(product: @product)

    get favorites_path
    assert_response :success
    assert_match "Vestido Floral", response.body
  end

  test "should favorite a product via HTML" do
    sign_in_as(@user)
    
    assert_difference("Favorite.count") do
      post product_favorite_path(@product)
    end

    assert_redirected_to product_path(@product)
    assert @user.favorited?(@product)
  end

  test "should favorite a product via Turbo Stream" do
    sign_in_as(@user)
    
    assert_difference("Favorite.count") do
      post product_favorite_path(@product), as: :turbo_stream
    end

    assert_response :success
    assert_match "turbo-stream", response.content_type
    assert @user.favorited?(@product)
  end

  test "should unfavorite a product via HTML" do
    sign_in_as(@user)
    @user.favorites.create!(product: @product)

    assert_difference("Favorite.count", -1) do
      delete product_favorite_path(@product)
    end

    assert_redirected_to product_path(@product)
    assert_not @user.favorited?(@product)
  end

  test "should unfavorite a product via Turbo Stream" do
    sign_in_as(@user)
    @user.favorites.create!(product: @product)

    assert_difference("Favorite.count", -1) do
      delete product_favorite_path(@product), as: :turbo_stream
    end

    assert_response :success
    assert_match "turbo-stream", response.content_type
    assert_not @user.favorited?(@product)
  end
end
