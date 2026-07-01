require "test_helper"

class OrdersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @buyer = users(:one)
    @other_user = users(:two)
    
    # Criamos um pedido associado ao comprador (buyer) para teste
    @order = Order.create!(
      user: @buyer,
      customer_name: "Buyer One",
      customer_email: "one@example.com",
      customer_phone: "11999999999",
      shipping_cep: "01001-000",
      shipping_address: "Praça da Sé, 123",
      payment_method: "pix",
      total_cents: 10000,
      shipping_cost_cents: 1500,
      status: "shipped",
      shipping_status: "shipped"
    )
  end

  test "should allow buyer to confirm delivery when status is shipped" do
    sign_in_as(@buyer)
    
    patch confirm_delivery_order_path(@order)
    
    assert_redirected_to order_path(@order)
    @order.reload
    assert_equal "completed", @order.status
    assert_equal "delivered", @order.shipping_status
    assert_equal "Recebimento confirmado! O pagamento foi liberado para o vendedor.", flash[:notice]
  end

  test "should not allow other users to confirm delivery" do
    sign_in_as(@other_user)
    
    patch confirm_delivery_order_path(@order)
    
    assert_redirected_to root_path
    assert_equal "Você não tem permissão para acessar este pedido.", flash[:alert]
    @order.reload
    assert_equal "shipped", @order.status # não alterado
  end

  test "should not allow confirmation for anonymous orders if not in session" do
    # Pedido sem usuário associado (compra anônima)
    anonymous_order = Order.create!(
      customer_name: "Anon",
      customer_email: "anon@example.com",
      customer_phone: "11999999999",
      shipping_cep: "01001-000",
      shipping_address: "Praça da Sé, 123",
      payment_method: "pix",
      total_cents: 10000,
      shipping_cost_cents: 1500,
      status: "shipped",
      shipping_status: "shipped"
    )

    # Tenta acessar de outra sessão sem ter feito a compra nela
    patch confirm_delivery_order_path(anonymous_order)

    assert_redirected_to new_session_path
    anonymous_order.reload
    assert_equal "shipped", anonymous_order.status
  end

  test "should not allow confirmation if status is not shipped" do
    sign_in_as(@buyer)
    @order.update!(status: "paid", shipping_status: "pending_shipment")

    patch confirm_delivery_order_path(@order)

    assert_redirected_to order_path(@order)
    assert_equal "Este pedido não pode ser confirmado neste status.", flash[:alert]
    @order.reload
    assert_equal "paid", @order.status # não alterado
  end

  test "should allow simulating payment when status is pending" do
    @order.update!(status: "pending")

    patch simulate_payment_order_path(@order)

    assert_redirected_to order_path(@order)
    assert_equal "Pagamento Pix simulado com sucesso! O status do pedido mudou para Pago.", flash[:notice]
    @order.reload
    assert_equal "paid", @order.status
  end

  test "should not allow simulating payment if status is not pending" do
    @order.update!(status: "shipped")

    patch simulate_payment_order_path(@order)

    assert_redirected_to order_path(@order)
    assert_equal "Este pedido não está pendente de pagamento.", flash[:alert]
    @order.reload
    assert_equal "shipped", @order.status # não alterado
  end
end
