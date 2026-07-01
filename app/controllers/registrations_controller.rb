class RegistrationsController < ApplicationController
  allow_unauthenticated_access only: [ :new, :create ]

  def new
    @user = User.new
  end

  def create
    @user = User.new(registration_params)

    # Garante que apenas papéis válidos sejam selecionados ('buyer' ou 'seller')
    # O papel 'admin' só pode ser definido via console/seeds
    @user.role = 'buyer' unless %w[buyer seller].include?(@user.role)

    if @user.save
      start_new_session_for @user
      dest = (@user.admin? || @user.seller?) ? admin_products_path : root_path
      redirect_to dest, notice: "Cadastro realizado com sucesso! Bem-vinda ao Brechó Ruby, #{@user.name}."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(
      :name, :email_address, :password, :role,
      :cep, :address_street, :address_number,
      :address_complement, :address_neighborhood,
      :address_city, :address_state
    )
  end
end
