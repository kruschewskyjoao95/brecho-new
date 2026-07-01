class Admin::BaseController < ApplicationController
  before_action :require_admin_or_seller

  private

  def require_admin_or_seller
    unless current_user && (current_user.admin? || current_user.seller?)
      redirect_to root_path, alert: "Você não tem permissão para acessar esta área."
    end
  end
end
