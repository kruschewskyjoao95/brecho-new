require "test_helper"

class OrderMailerTest < ActionMailer::TestCase
  setup do
    @seller = users(:one)
    @seller.update!(role: "seller")
    
    @order = Order.create!(
      seller: @seller,
      customer_name: "John Buyer",
      customer_email: "buyer@email.com",
      customer_phone: "11999999999",
      shipping_cep: "01001-000",
      shipping_address: "Rua do Comprador, 123",
      payment_method: "pix",
      total_cents: 15000,
      shipping_cost_cents: 2000,
      status: "pending",
      shipping_status: "pending_shipment"
    )

    # Criamos um item associado para o teste de visualização do resumo
    Product.create!(id: 999, name: "Calça Jeans", price_cents: 13000, category: "Calças", stock: 1, active: true, seller: @seller)
    @order.order_items.create!(product_id: 999, quantity: 1, price_cents: 13000)
  end

  test "payment_confirmed_buyer" do
    email = OrderMailer.payment_confirmed_buyer(@order)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["contato@brechoruby.com.br"], email.from
    assert_equal ["buyer@email.com"], email.to
    assert_equal "Pagamento confirmado! Seu pedido ##{@order.id} no Brechó Ruby está sendo preparado", email.subject
    assert_match "Oba! Seu pagamento foi confirmado!", email.body.to_s
    assert_match "Calça Jeans", email.body.to_s
  end

  test "sale_notification_seller" do
    email = OrderMailer.sale_notification_seller(@order)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["contato@brechoruby.com.br"], email.from
    assert_equal [@seller.email_address], email.to
    assert_equal "Você realizou uma venda! Prepare o envio do pedido ##{@order.id}", email.subject
    assert_match "Parabéns! Você realizou uma venda!", email.body.to_s
    assert_match "Calça Jeans", email.body.to_s
  end

  test "order_shipped_buyer" do
    @order.update!(tracking_code: "BR123456789BR")
    email = OrderMailer.order_shipped_buyer(@order)

    assert_emails 1 do
      email.deliver_now
    end

    assert_equal ["contato@brechoruby.com.br"], email.from
    assert_equal ["buyer@email.com"], email.to
    assert_equal "Seu pedido ##{@order.id} foi enviado! Acompanhe o rastreamento", email.subject
    assert_match "Seu pedido está a caminho!", email.body.to_s
    assert_match "BR123456789BR", email.body.to_s
  end
end
