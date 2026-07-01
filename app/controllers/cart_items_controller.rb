class CartItemsController < ApplicationController
  allow_unauthenticated_access
  include CurrentCart
  before_action :set_cart
  before_action :set_cart_item, only: [ :update, :destroy ]

  def create
    product = Product.find(params[:product_id])
    quantity = params[:quantity].to_i
    quantity = 1 if quantity <= 0

    # Validação de vendedor único no carrinho
    if @cart.cart_items.any?
      existing_seller = @cart.cart_items.first.product.seller
      if existing_seller != product.seller
        seller_name = existing_seller ? existing_seller.name : "Brechó Ruby"
        respond_to do |format|
          format.html { redirect_back fallback_location: products_path, alert: "Seu carrinho já possui peças do vendedor '#{seller_name}'. Por favor, finalize a compra atual ou esvazie o carrinho antes de adicionar peças de outro vendedor." }
          format.turbo_stream { render turbo_stream: turbo_stream.append("flash-messages", partial: "layouts/flash", locals: { message_type: :alert, message: "Carrinho já possui peças do vendedor '#{seller_name}'." }) }
        end
        return
      end
    end

    size = params[:size].presence || product.sizes.to_s.split(',').first&.strip
    color = params[:color].presence || product.colors.to_s.split(',').first&.strip

    @cart_item = @cart.cart_items.find_by(product_id: product.id, size: size, color: color)
    if @cart_item
      @cart_item.quantity += quantity
    else
      @cart_item = @cart.cart_items.build(product: product, quantity: quantity, size: size, color: color)
    end

    respond_to do |format|
      if @cart_item.save
        format.html { redirect_to products_path, notice: "#{product.name} adicionado ao carrinho!" }
        format.turbo_stream
      else
        format.html { redirect_to products_path, alert: "Não foi possível adicionar o produto ao carrinho." }
      end
    end
  end

  def update
    if params[:quantity].to_i <= 0
      @cart_item.destroy
    else
      @cart_item.update(quantity: params[:quantity].to_i)
    end

    respond_to do |format|
      format.html { redirect_to cart_path }
      format.turbo_stream
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
