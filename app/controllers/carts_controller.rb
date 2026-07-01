class CartsController < ApplicationController
  allow_unauthenticated_access
  include CurrentCart
  before_action :set_cart

  def show
    # @cart set by before_action
  end

  def destroy
    @cart.cart_items.destroy_all
    respond_to do |format|
      format.html { redirect_to products_path, notice: "Seu carrinho está vazio." }
      format.turbo_stream
    end
  end
end
