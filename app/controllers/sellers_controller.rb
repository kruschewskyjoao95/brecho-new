class SellersController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    @seller = User.find(params[:id])
    
    # Garante que o usuário acessado é um vendedor ou admin
    unless @seller.seller? || @seller.admin?
      redirect_to root_path, alert: "Vendedor não encontrado."
      return
    end

    query = @seller.products.where(active: true).includes(images_attachments: :blob, favorites: :user).order(created_at: :desc)
    @pagy, @products = pagy(query, limit: 12)
  end
end
