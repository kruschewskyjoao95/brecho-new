class CartItemsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_cart_item, only: [ :update, :destroy ]

  def create
    product = Product.find(params[:product_id])
    
    # 1. Valida se o produto está ativo
    unless product.active?
      respond_to do |format|
        format.html { redirect_back fallback_location: products_path, alert: "Esta peça não está mais disponível para venda." }
        format.turbo_stream { render turbo_stream: turbo_stream.append("flash-messages", partial: "layouts/flash", locals: { message_type: :alert, message: "Peça indisponível para venda." }) }
      end
      return
    end

    # Validação de vendedor único no carrinho (Corrigindo N+1 com JOIN)
    if @cart.cart_items.any?
      existing_seller_id = @cart.cart_items.joins(:product).pick("products.user_id")
      if existing_seller_id != product.user_id
        seller_name = existing_seller_id ? User.find(existing_seller_id).name : "Brechó Ruby"
        respond_to do |format|
          format.html { redirect_back fallback_location: products_path, alert: "Seu carrinho já possui peças do vendedor '#{seller_name}'. Finalize ou esvazie o carrinho antes de adicionar peças de outro vendedor." }
          format.turbo_stream { render turbo_stream: turbo_stream.append("flash-messages", partial: "layouts/flash", locals: { message_type: :alert, message: "Carrinho já possui peças do vendedor '#{seller_name}'." }) }
        end
        return
      end
    end

    quantity = params[:quantity].to_i
    quantity = 1 if quantity <= 0
    size = params[:size].presence || product.sizes.to_s.split(',').first&.strip
    color = params[:color].presence || product.colors.to_s.split(',').first&.strip

    success = false
    
    begin
      ActiveRecord::Base.transaction do
        locked_product = Product.lock.find(product.id)
        
        # 2. Valida se a quantidade pedida cabe no estoque disponível
        existing_qty = @cart.cart_items.where(product_id: locked_product.id).sum(:quantity)
        if existing_qty + quantity > locked_product.stock
          raise ActiveRecord::RecordInvalid.new(locked_product)
        end

        @cart_item = @cart.cart_items.find_or_initialize_by(product_id: locked_product.id, size: size, color: color)
        @cart_item.quantity = (@cart_item.new_record? ? quantity : @cart_item.quantity + quantity)
        @cart_item.save!
        success = true
      end
    rescue ActiveRecord::RecordInvalid
      respond_to do |format|
        format.html { redirect_back fallback_location: products_path, alert: "Estoque insuficiente. '#{product.name}' possui apenas #{product.stock} unidade(s) disponível(is)." }
        format.turbo_stream { render turbo_stream: turbo_stream.append("flash-messages", partial: "layouts/flash", locals: { message_type: :alert, message: "Estoque insuficiente para '#{product.name}'." }) }
      end
      return
    end

    respond_to do |format|
      if success
        format.html { redirect_to products_path, notice: "#{product.name} adicionado ao carrinho!" }
        format.turbo_stream
      else
        format.html { redirect_to products_path, alert: "Não foi possível adicionar o produto ao carrinho." }
      end
    end
  end

  def update
    requested_qty = params[:quantity].to_i
    if requested_qty <= 0
      @cart_item.destroy
    else
      ActiveRecord::Base.transaction do
        locked_product = Product.lock.find(@cart_item.product_id)
        if requested_qty > locked_product.stock
          respond_to do |format|
            format.html { redirect_to cart_path, alert: "Estoque insuficiente. '#{locked_product.name}' possui apenas #{locked_product.stock} unidades." }
            format.turbo_stream { render turbo_stream: turbo_stream.append("flash-messages", partial: "layouts/flash", locals: { message_type: :alert, message: "Estoque insuficiente para '#{locked_product.name}'." }) }
          end
          raise ActiveRecord::Rollback
        end
        @cart_item.update!(quantity: requested_qty)
      end
    end

    # If the transaction rolls back, we still want to render turbo stream if it hasn't responded yet
    unless performed?
      respond_to do |format|
        format.html { redirect_to cart_path }
        format.turbo_stream
      end
    end
  end

  def destroy
    @cart_item.destroy
    respond_to do |format|
      format.html { redirect_to cart_path, notice: "Produto removido do carrinho." }
      format.turbo_stream
    end
  end

  private

  def set_cart_item
    @cart_item = @cart.cart_items.find(params[:id])
  end
end
