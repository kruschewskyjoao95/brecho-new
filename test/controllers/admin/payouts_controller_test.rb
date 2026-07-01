require "test_helper"

class Admin::PayoutsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @seller = users(:one)
    @seller.update!(role: "seller")
    
    # Adicionamos uma venda completada de R$ 100,00 para dar saldo disponível à Clara (comissão 10% -> R$ 90,00 de saldo)
    @order = Order.create!(
      seller: @seller,
      customer_name: "Client One",
      customer_email: "client@email.com",
      customer_phone: "11999999999",
      shipping_cep: "01001-000",
      shipping_address: "Praça da Sé, 123",
      payment_method: "pix",
      total_cents: 10000,
      shipping_cost_cents: 0, # sem frete
      status: "completed",
      shipping_status: "delivered"
    )
  end

  test "should create payout request when having enough balance" do
    sign_in_as(@seller)
    
    assert_difference("Payout.count") do
      post admin_payouts_path, params: {
        payout: {
          amount: 50.00,
          pix_key_type: "cpf",
          pix_key: "123.456.789-00"
        }
      }
    end

    assert_redirected_to admin_financial_path
    assert_equal "Saque solicitado com sucesso! O valor será transferido em até 24 horas úteis para a chave Pix indicada.", flash[:notice]
    
    payout = Payout.last
    assert_equal 5000, payout.amount_cents
    assert_equal "pending", payout.status
    assert_equal "cpf", payout.pix_key_type
    assert_equal "123.456.789-00", payout.pix_key
  end

  test "should not create payout request if amount is greater than available balance" do
    sign_in_as(@seller)
    
    assert_no_difference("Payout.count") do
      post admin_payouts_path, params: {
        payout: {
          amount: 100.00, # Ela só tem R$ 90.00 disponível
          pix_key_type: "email",
          pix_key: "clara@email.com"
        }
      }
    end

    assert_redirected_to admin_financial_path
    assert_equal "Saldo disponível insuficiente para realizar o saque.", flash[:alert]
  end

  test "should not create payout request if amount is <= 0" do
    sign_in_as(@seller)
    
    assert_no_difference("Payout.count") do
      post admin_payouts_path, params: {
        payout: {
          amount: -5.00,
          pix_key_type: "email",
          pix_key: "clara@email.com"
        }
      }
    end

    assert_redirected_to admin_financial_path
    assert_equal "O valor do saque deve ser maior que R$ 0,00.", flash[:alert]
  end
end
