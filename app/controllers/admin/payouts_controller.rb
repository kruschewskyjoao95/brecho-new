class Admin::PayoutsController < Admin::BaseController
  def create
    @user = current_user
    amount_value = payout_params[:amount].to_f
    amount_cents = (amount_value * 100).round

    if amount_cents <= 0
      redirect_to admin_financial_path, alert: "O valor do saque deve ser maior que R$ 0,00."
      return
    end

    success = false
    error_message = nil

    ActiveRecord::Base.transaction do
      locked_user = User.lock.find(current_user.id)
      saldo_cents = (locked_user.saldo_disponivel * 100).round

      if amount_cents > saldo_cents
        error_message = "Saldo disponível insuficiente para realizar o saque."
        raise ActiveRecord::Rollback
      end

      @payout = locked_user.payouts.build(payout_params)
      @payout.status = "pending"

      if @payout.save
        locked_user.decrement!(:saldo_disponivel, amount_value)
        success = true
      else
        error_message = "Erro ao processar solicitação: #{@payout.errors.full_messages.join(', ')}"
        raise ActiveRecord::Rollback
      end
    end

    if success
      redirect_to admin_financial_path, notice: "Saque solicitado com sucesso! O valor será transferido em até 24 horas úteis para a chave Pix indicada."
    else
      redirect_to admin_financial_path, alert: error_message || "Não foi possível processar o saque."
    end
  end

  private

  def payout_params
    params.require(:payout).permit(:amount, :pix_key_type, :pix_key)
  end
end
