class Admin::PayoutsController < Admin::BaseController
  def create
    @user = current_user
    @payout = @user.payouts.build(payout_params)
    @payout.status = "pending"

    if @payout.amount <= 0
      redirect_to admin_financial_path, alert: "O valor do saque deve ser maior que R$ 0,00."
      return
    end

    ActiveRecord::Base.transaction do
      locked_user = User.lock.find(current_user.id)
      
      if @payout.amount > locked_user.saldo_disponivel
        redirect_to admin_financial_path, alert: "Saldo disponível insuficiente para realizar o saque."
        raise ActiveRecord::Rollback
      end

      if @payout.save
        redirect_to admin_financial_path, notice: "Saque solicitado com sucesso! O valor será transferido em até 24 horas úteis para a chave Pix indicada."
      else
        redirect_to admin_financial_path, alert: "Erro ao processar solicitação: #{@payout.errors.full_messages.join(', ')}"
        raise ActiveRecord::Rollback
      end
    end
  end

  private

  def payout_params
    params.require(:payout).permit(:amount, :pix_key_type, :pix_key)
  end
end
