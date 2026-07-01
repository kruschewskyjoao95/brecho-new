class SitemapsController < ApplicationController
  allow_unauthenticated_access

  def show
    @products = Product.where(active: true)
    
    respond_to do |format|
      format.xml
    end
  end
end
