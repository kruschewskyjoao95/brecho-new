class SellersController < ApplicationController
  allow_unauthenticated_access only: [ :show ]

  def show
    @seller = User.find(params[:id])
    
    # Garante que o usuário acessado é um vendedor ou admin
    unless @seller.seller? || @seller.admin?
      redirect_to root_path, alert: "Vendedor não encontrado."
      return
    end

    @products = @seller.products.where(active: true).order(created_at: :desc)
  end
end
