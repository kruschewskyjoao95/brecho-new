class OrdersController < ApplicationController
  allow_unauthenticated_access
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

    address_parts = []
    address_parts << street if street.present?
    address_parts << "nº #{number}" if number.present?
    address_parts << comp if comp.present?
    address_parts << neighborhood if neighborhood.present?
    address_parts << "#{city}/#{state}" if city.present? && state.present?
    @order.shipping_address = address_parts.join(" - ")

    # 1. Recalcula o frete escolhido para garantir segurança (Evita injeção de preço)
    shipping_method = params[:shipping_method]
    origin_cep = @order.seller&.cep
    
    # Recalcula opções reais do servidor
    valid_shipping_options = CalculateShippingService.new(
      destination_cep: @order.shipping_cep, 
      origin_cep: origin_cep
    ).call
    
    selected_option = valid_shipping_options.find { |opt| opt[:id] == shipping_method }

    unless selected_option
      @order.errors.add(:base, "Opção de frete inválida ou não encontrada.")
      @shipping_options = valid_shipping_options
      render :new, status: :unprocessable_entity
      return
    end

    @order.shipping_cost = selected_option[:price]
    @order.shipping_method = selected_option[:name]

    # 2. Calcula total dos produtos + frete
    subtotal_cents = @cart.total_cents(authenticated? ? current_user : nil)
    @order.total_cents = subtotal_cents + @order.shipping_cost_cents

    # 3. Tenta salvar o pedido e processar os itens em uma transação atômica
    success = false
    payment_error = nil

    ActiveRecord::Base.transaction do
      # Prepara bulk data: Locks ordenados para evitar deadlocks e offers pre-carregadas para evitar N+1
      product_ids = @cart.cart_items.map(&:product_id)
      locked_products = Product.where(id: product_ids).order(:id).lock.index_by(&:id)
      
      accepted_offers = {}
      if authenticated?
        accepted_offers = Offer.where(buyer: current_user, product_id: product_ids, status: "accepted").index_by(&:product_id)
      end

      # 1. Valida e decrementa estoque de cada produto
      @cart.cart_items.each do |item|
        product = locked_products[item.product_id] # Pega do hash já travado sequencialmente
        if product.stock < item.quantity
          @order.errors.add(:base, "A peça '#{product.name}' não possui estoque disponível suficiente.")
          raise ActiveRecord::Rollback
        end
        product.decrement!(:stock, item.quantity)
      end

      # 2. Salva os dados básicos do pedido
      if @order.save
        # 3. Transfere os itens do carrinho para o pedido
        @cart.cart_items.each do |item|
          product = locked_products[item.product_id]
          price = product.price_promo_cents || product.price_cents
          
          if authenticated? && accepted_offers[product.id]
            price = accepted_offers[product.id].amount_cents
          end

          @order.order_items.create!(
            product: item.product,
            quantity: item.quantity,
            price_cents: price,
            size: item.size,
            color: item.color
          )
        end

        # 4. Processa o pagamento via AsaasPaymentService
        payment_params = params.slice(:payment_token, :installments)
        payment_service = AsaasPaymentService.new(@order, payment_params)
        payment_result = payment_service.process

        if payment_result[:success]
          success = true
        else
          payment_error = payment_result[:error]
          raise ActiveRecord::Rollback
        end
      else
        raise ActiveRecord::Rollback
      end
    end

    if success
      # Esvazia o carrinho de compras
      @cart.cart_items.destroy_all
      session[:cart_token] = nil
      
      unless authenticated?
        session[:guest_order_ids] ||= []
        session[:guest_order_ids] << @order.id
        session[:guest_order_ids] = session[:guest_order_ids].last(10) # Limita tamanho do array
      end

      redirect_to order_path(@order), notice: "Pedido realizado com sucesso!"
    else
      flash.now[:alert] = payment_error ? "Falha no pagamento: #{payment_error}" : "Não foi possível finalizar o pedido. Verifique os dados ou estoque das peças."
      
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

    # Validação de Autorização: Apenas o comprador, o vendedor ou um admin
    if authenticated?
      unless current_user == @order.user || current_user == @order.seller || current_user.admin?
        redirect_to root_path, alert: "Você não tem permissão para acessar esta ação."
        return
      end
    else
      guest_orders = session[:guest_order_ids] || []
      unless guest_orders.include?(@order.id)
        redirect_to new_session_path, alert: "Faça login para realizar esta simulação."
        return
      end
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
