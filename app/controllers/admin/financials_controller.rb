class Admin::FinancialsController < Admin::BaseController
  def show
    @user = current_user
    @payouts = @user.payouts.order(created_at: :desc)
    @payout = Payout.new
  end
end
