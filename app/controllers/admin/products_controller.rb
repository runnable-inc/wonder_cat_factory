class Admin::ProductsController < Manage::ProductsController
  include AdminController

  before_action :set_user, only: [:index]

  # GET /admin/products
  # GET /admin/users/1/products
  def index
    @products = (@user.try(:products) || Product)
                .newer_first
                .page(params[:page])
  end

  private

  def set_user
    @user = User.find(params[:user_id]) if params.key?(:user_id)
  end
end
