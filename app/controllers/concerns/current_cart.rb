module CurrentCart
  extend ActiveSupport::Concern

  private

  def set_cart
    token = session[:cart_token]
    if token.nil?
      token = SecureRandom.hex(16)
      session[:cart_token] = token
    end
    @cart = Cart.find_or_create_by!(session_token: token)
  end
end
