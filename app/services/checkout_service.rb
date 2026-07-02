class CheckoutService
  def initialize(order:, cart:, user:, params:)
    @order = order
    @cart = cart
    @user = user
    @params = params
  end

  def call
    build_order
    validate_shipping
    return { success: false, error: @order.errors.full_messages.first } if @order.errors.any?

    calculate_totals

    success = false
    payment_error = nil

    ActiveRecord::Base.transaction do
      lock_products
      
      unless validate_and_decrement_stock
        raise ActiveRecord::Rollback
      end

      if @order.save
        create_order_items
        
        # Processa o pagamento via AsaasPaymentService com todos os dados de cartão
        payment_params = @params.slice(:payment_token, :installments, :card_number, :card_name, :card_expiry, :card_cvv)
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
      { success: true }
    else
      { success: false, error: payment_error || "Não foi possível finalizar o pedido. Verifique os dados ou estoque das peças." }
    end
  end

  private

  def build_order
    @order.user = @user if @user
    
    first_item = @cart.cart_items.first
    @order.seller = first_item.product.seller if first_item

    street = @params[:shipping_street]
    number = @params[:shipping_number]
    comp = @params[:shipping_complement]
    neighborhood = @params[:shipping_neighborhood]
    city = @params[:shipping_city]
    state = @params[:shipping_state]

    address_parts = []
    address_parts << street if street.present?
    address_parts << "nº #{number}" if number.present?
    address_parts << comp if comp.present?
    address_parts << neighborhood if neighborhood.present?
    address_parts << "#{city}/#{state}" if city.present? && state.present?
    @order.shipping_address = address_parts.join(" - ")
  end

  def validate_shipping
    shipping_method = @params[:shipping_method]
    origin_cep = @order.seller&.cep
    
    valid_shipping_options = CalculateShippingService.new(
      destination_cep: @order.shipping_cep, 
      origin_cep: origin_cep
    ).call
    
    selected_option = valid_shipping_options.find { |opt| opt[:id] == shipping_method }

    unless selected_option
      @order.errors.add(:base, "Opção de frete inválida ou não encontrada.")
      return
    end

    @order.shipping_cost = selected_option[:price]
    @order.shipping_method = selected_option[:name]
  end

  def calculate_totals
    subtotal_cents = @cart.total_cents(@user)
    @order.total_cents = subtotal_cents + @order.shipping_cost_cents
  end

  def lock_products
    product_ids = @cart.cart_items.map(&:product_id)
    @locked_products = Product.where(id: product_ids).order(:id).lock.index_by(&:id)
    
    @accepted_offers = {}
    if @user
      @accepted_offers = Offer.where(buyer: @user, product_id: product_ids, status: "accepted").index_by(&:product_id)
    end
  end

  def validate_and_decrement_stock
    @cart.cart_items.each do |item|
      product = @locked_products[item.product_id]
      if product.stock < item.quantity
        @order.errors.add(:base, "A peça '#{product.name}' não possui estoque disponível suficiente.")
        return false
      end
      product.decrement!(:stock, item.quantity)
    end
    true
  end

  def create_order_items
    @cart.cart_items.each do |item|
      product = @locked_products[item.product_id]
      price = product.price_promo_cents || product.price_cents
      
      if @user && @accepted_offers[product.id]
        price = @accepted_offers[product.id].amount_cents
      end

      @order.order_items.create!(
        product: item.product,
        quantity: item.quantity,
        price_cents: price,
        size: item.size,
        color: item.color
      )
    end
  end
end
