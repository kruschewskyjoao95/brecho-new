class Admin::OffersController < Admin::BaseController
  before_action :set_offer, only: [:update]

  def index
    # Offers made on the current user's products
    @received_offers = current_user.received_offers.includes(:product, :buyer).order(created_at: :desc)
    # Offers the current user made
    @made_offers = current_user.offers.includes(:product).order(created_at: :desc)
  end

  def update
    action = params[:offer_action]
    
    case action
    when "accept"
      if @offer.update(status: "accepted")
        redirect_to admin_offers_path, notice: "Oferta aceita! O comprador já pode finalizar a compra com o valor combinado."
      else
        redirect_to admin_offers_path, alert: "Erro ao aceitar oferta."
      end
    when "reject"
      if @offer.update(status: "rejected")
        redirect_to admin_offers_path, notice: "Oferta recusada."
      else
        redirect_to admin_offers_path, alert: "Erro ao recusar oferta."
      end
    else
      redirect_to admin_offers_path, alert: "Ação inválida."
    end
  end

  private

  def set_offer
    @offer = current_user.received_offers.find(params[:id])
  end
end
