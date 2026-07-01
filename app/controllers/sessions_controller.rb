class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[ new create ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_path, alert: "Try again later." }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for user
      dest = (user.admin? || user.seller?) ? admin_products_path : root_path
      redirect_to dest, notice: "Bem-vinda de volta, #{user.name}!"
    else
      redirect_to new_session_path, alert: "E-mail ou senha incorretos."
    end
  end

  def destroy
    terminate_session
    redirect_to root_path, notice: "Sessão encerrada com sucesso."
  end
end
