class Admin::AdCreditsController < Admin::BaseController
  def new
  end

  def create
    unless Rails.env.development? || Rails.env.test?
      redirect_to admin_products_path, alert: "A compra de créditos reais está temporariamente desativada em produção."
      return
    end

    # Simula o fluxo de pagamento para a liberação do anúncio extra de R$ 5,99 no modo de desenvolvimento.
    current_user.increment!(:extra_ad_credits)
    
    redirect_to new_admin_product_path, notice: "[Modo Dev] Pagamento simulado! Seu anúncio extra foi liberado."
  end
end
