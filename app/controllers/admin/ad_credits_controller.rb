class Admin::AdCreditsController < Admin::BaseController
  def new
  end

  def create
    # Simula o fluxo de pagamento para a liberação do anúncio extra de R$ 5,99.
    # Em um sistema real, isso chamaria o gateway (ex: Stripe ou Asaas) para gerar um PIX/Cartão.
    # Como é uma simulação, vamos aprovar imediatamente e creditar.
    
    current_user.increment!(:extra_ad_credits)
    
    redirect_to new_admin_product_path, notice: "Pagamento confirmado! Seu anúncio extra foi liberado e você pode cadastrá-lo agora com até 5 fotos."
  end
end
