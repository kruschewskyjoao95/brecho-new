require "test_helper"

class ReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:one)
    @buyer.update!(role: "buyer")
    
    @seller = users(:two)
    @seller.update!(role: "seller")
    
    @order = Order.create!(
      user: @buyer,
      seller: @seller,
      customer_name: "Buyer One",
      customer_email: "buyer@email.com",
      customer_phone: "11999999999",
      shipping_cep: "01001-000",
      shipping_address: "Address 1",
      payment_method: "pix",
      total_cents: 10000,
      shipping_cost_cents: 0,
      status: "completed",
      shipping_status: "delivered"
    )
  end

  test "should create review on completed order" do
    sign_in_as(@buyer)
    
    assert_difference("Review.count") do
      post order_reviews_path(@order), params: {
        review: {
          rating: 5,
          comment: "Ótima peça, adorei o carinho no envio!"
        }
      }
    end

    assert_redirected_to order_path(@order)
    assert_equal "Obrigado! Sua avaliação foi enviada com sucesso.", flash[:notice]
    
    review = Review.last
    assert_equal 5, review.rating
    assert_equal "Ótima peça, adorei o carinho no envio!", review.comment
    assert_equal @buyer, review.buyer
    assert_equal @seller, review.seller
  end

  test "should not allow review if order is not completed" do
    sign_in_as(@buyer)
    @order.update!(status: "paid")
    
    assert_no_difference("Review.count") do
      post order_reviews_path(@order), params: {
        review: { rating: 4, comment: "Legal" }
      }
    end

    assert_redirected_to order_path(@order)
    assert_equal "Você só pode avaliar a compra após confirmar o recebimento.", flash[:alert]
  end

  test "should not allow review if already reviewed" do
    sign_in_as(@buyer)
    
    # Cria a primeira avaliação
    @order.create_review!(rating: 5, buyer: @buyer, seller: @seller)
    
    assert_no_difference("Review.count") do
      post order_reviews_path(@order), params: {
        review: { rating: 3, comment: "Mudei de ideia" }
      }
    end

    assert_redirected_to order_path(@order)
    assert_equal "Este pedido já foi avaliado.", flash[:alert]
  end

  test "should not allow review by someone else" do
    other_user = users(:two)
    sign_in_as(other_user)
    
    assert_no_difference("Review.count") do
      post order_reviews_path(@order), params: {
        review: { rating: 5, comment: "Invasor" }
      }
    end

    assert_redirected_to order_path(@order)
    assert_equal "Você não tem permissão para avaliar este pedido.", flash[:alert]
  end
end
