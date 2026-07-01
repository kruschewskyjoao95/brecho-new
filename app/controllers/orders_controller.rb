class OrdersController < ApplicationController
  allow_unauthenticated_access
  include CurrentCart
  before_action :set_cart, only: [ :new, :create, :calculate_shipping ]
  before_action :ensure_cart_not_empty, only: [ :new, :create ]
  before_action :set_order_and_authorize, only: [ :show, :confirm_delivery ]

  def new
    @order = Order.new
    @shipping_options = []
  end

  def create
    @order = Order.new(order_params)
    @order.user = current_user if authenticated?
    
    # Define o vendedor do pedido com base nos itens do carrinho
    first_item = @cart.cart_items.first
    @order.seller = first_item.product.seller if first_item

    # Constrói o endereço completo a partir dos campos separados do formulário
    street = params[:shipping_street]
    number = params[:shipping_number]
    comp = params[:shipping_complement]
    neighborhood = params[:shipping_neighborhood]
    city = params[:shipping_city]
    state = params[:shipping_state]

    address_parts = [street, "nº #{number}"]
    address_parts << comp if comp.present?
    address_parts << neighborhood
    address_parts << "#{city}/#{state}"
    @order.shipping_address = address_parts.join(" - ")

    # 1. Calcula o frete escolhido
    shipping_cost = params[:shipping_cost].to_f
    shipping_method = params[:shipping_method]
    @order.shipping_cost = shipping_cost
    @order.shipping_method = shipping_method

    # 2. Calcula total dos produtos + frete
    subtotal_cents = @cart.total_cents
    @order.total_cents = subtotal_cents + @order.shipping_cost_cents

    # 3. Salva os dados básicos do pedido
    if @order.save
      # 4. Transfere os itens do carrinho para o pedido
      @cart.cart_items.each do |item|
        @order.order_items.create!(
          product: item.product,
          quantity: item.quantity,
          price_cents: item.product.price_promo_cents || item.product.price_cents,
          size: item.size,
          color: item.color
        )
      end

      # 5. Processa o pagamento via AsaasPaymentService
      payment_params = params.slice(:payment_token, :installments)
      payment_service = AsaasPaymentService.new(@order, payment_params)
      payment_result = payment_service.process

      if payment_result[:success]
        # Esvazia o carrinho de compras
        @cart.cart_items.destroy_all
        session[:cart_token] = nil
        
        unless authenticated?
          session[:guest_order_ids] ||= []
          session[:guest_order_ids] << @order.id
        end

        redirect_to order_path(@order), notice: "Pedido realizado com sucesso!"
      else
        @order.destroy # desfaz pedido se pagamento falhar
        flash.now[:alert] = "Falha no pagamento: #{payment_result[:error]}"
        
        first_item = @cart.cart_items.first
        origin_cep = first_item&.product&.seller&.cep
        @shipping_options = CalculateShippingService.new(destination_cep: @order.shipping_cep, origin_cep: origin_cep).call
        render :new, status: :unprocessable_entity
      end
    else
      first_item = @cart.cart_items.first
      origin_cep = first_item&.product&.seller&.cep
      @shipping_options = CalculateShippingService.new(destination_cep: @order.shipping_cep, origin_cep: origin_cep).call
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if @order.tracking_code.present?
      @tracking_events = TrackShipmentService.new(@order.tracking_code, @order.status).call
    end
  end

  def confirm_delivery
    if @order.status == 'shipped'
      @order.update!(status: 'completed', shipping_status: 'delivered')
      redirect_to order_path(@order), notice: "Recebimento confirmado! O pagamento foi liberado para o vendedor."
    else
      redirect_to order_path(@order), alert: "Este pedido não pode ser confirmado neste status."
    end
  end

  def simulate_payment
    @order = Order.find(params[:id])
    
    unless Rails.env.development? || Rails.env.test?
      redirect_to order_path(@order), alert: "Esta ação só está disponível em ambiente de desenvolvimento."
      return
    end

    if @order.status == 'pending'
      @order.update!(status: 'paid')
      redirect_to order_path(@order), notice: "Pagamento Pix simulado com sucesso! O status do pedido mudou para Pago."
    else
      redirect_to order_path(@order), alert: "Este pedido não está pendente de pagamento."
    end
  end

  # Endpoint para calcular o frete via Ajax/Turbo Stream
  def calculate_shipping
    cep = params[:cep]
    first_item = @cart.cart_items.first
    origin_cep = first_item&.product&.seller&.cep
    @shipping_options = CalculateShippingService.new(destination_cep: cep, origin_cep: origin_cep).call

    respond_to do |format|
      format.turbo_stream
      format.html { render partial: "shipping_options", locals: { shipping_options: @shipping_options } }
    end
  end

  private

  def set_order_and_authorize
    @order = Order.find(params[:id])
    
    if authenticated?
      unless current_user == @order.user || current_user == @order.seller || current_user.admin?
        redirect_to root_path, alert: "Você não tem permissão para acessar este pedido."
      end
    else
      guest_orders = session[:guest_order_ids] || []
      unless guest_orders.include?(@order.id)
        redirect_to new_session_path, alert: "Faça login para ver este pedido."
      end
    end
  end

  def order_params
    params.require(:order).permit(
      :customer_name, :customer_email, :customer_phone,
      :shipping_cep, :payment_method
    )
  end

  def ensure_cart_not_empty
    if @cart.cart_items.empty?
      redirect_to products_path, alert: "Seu carrinho está vazio!"
    end
  end
end
