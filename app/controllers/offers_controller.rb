class OffersController < ApplicationController
  before_action :require_authentication

  def create
    @product = Product.find(params[:product_id])
    
    if @product.seller == current_user
      redirect_to product_path(@product), alert: "Você não pode fazer uma oferta no seu próprio produto."
      return
    end

    @offer = @product.offers.build(offer_params)
    @offer.buyer = current_user
    @offer.status = "pending"

    if @offer.save
      redirect_to product_path(@product), notice: "Sua oferta de R$ #{ActionController::Base.helpers.number_with_precision(@offer.amount, precision: 2)} foi enviada para o vendedor!"
    else
      redirect_to product_path(@product), alert: "Erro ao enviar oferta: #{@offer.errors.full_messages.join(', ')}"
    end
  end

  private

  def offer_params
    params.require(:offer).permit(:amount)
  end
end
