class ProfilesController < ApplicationController
  def edit
    @user = current_user
  end

  def update
    @user = current_user
    if @user.update(profile_params)
      redirect_to edit_profile_path, notice: "Seu perfil foi atualizado com sucesso!"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    p = params.require(:user).permit(
      :name, :email_address, :password,
      :cep, :address_street, :address_number,
      :address_complement, :address_neighborhood,
      :address_city, :address_state, :bio, :avatar
    )
    p.delete(:password) if p[:password].blank?
    p
  end
end
