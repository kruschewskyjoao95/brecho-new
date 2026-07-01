class FavoritesController < ApplicationController
  # Todas as ações exigem login (comportamento padrão)

  def index
    @pagy, @favorite_products = pagy(current_user.favorite_products.order(created_at: :desc), limit: 20)
  end

  def create
    @product = Product.find(params[:product_id])
    current_user.favorites.find_or_create_by!(product: @product)

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: product_path(@product), notice: "Adicionado aos favoritos." }
    end
  end

  def destroy
    @product = Product.find(params[:product_id])
    current_user.favorites.find_by(product: @product)&.destroy

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_back fallback_location: product_path(@product), notice: "Removido dos favoritos." }
    end
  end
end
