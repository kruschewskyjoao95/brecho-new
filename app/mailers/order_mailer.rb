class OrderMailer < ApplicationMailer
  default from: "contato@brechoruby.com.br"

  # E-mail para o comprador confirmando o pagamento
  def payment_confirmed_buyer(order)
    @order = order
    mail(to: @order.customer_email, subject: "Pagamento confirmado! Seu pedido ##{@order.id} no Brechó Ruby está sendo preparado")
  end

  # E-mail para o vendedor informando sobre a nova venda
  def sale_notification_seller(order)
    @order = order
    @seller = @order.seller
    recipient = @seller ? @seller.email_address : "contato@amelialookbook.com.br"
    
    mail(to: recipient, subject: "Você realizou uma venda! Prepare o envio do pedido ##{@order.id}")
  end

  # E-mail para o comprador informando que o produto foi enviado
  def order_shipped_buyer(order)
    @order = order
    mail(to: @order.customer_email, subject: "Seu pedido ##{@order.id} foi enviado! Acompanhe o rastreamento")
  end
end
