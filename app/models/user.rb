class User < ActiveRecord::Base
  has_many :products, dependent: :destroy
  has_many :bids, dependent: :destroy
  has_many :system_messages
  has_one :stripe_account

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable, :confirmable

  scope :admin, -> { where(is_admin: true) }
  scope :seller, -> { where(is_seller: true) }

  def to_s
    label.presence || email
  end

  def admin?
    is_admin?
  end

  def seller?
    is_seller?
  end

  def age
    birthday.present? ? Time.current.year - birthday.year : nil
  end

  def bid product
    bids.create(product: product)
  end

  def bidded? product
    @bidded_product_ids ||= bids.pluck(:product_id)
    @bidded_product_ids.include? product.id
  end

  def update_purchased product
    bids.where(product: product).update_all paid_at: Time.current
  end

  def attach_stripe_account!
    Stripe::Account.create(
      email: email,
      managed: true,
      country: 'JP'
    ).tap do |account|
      account_attrs = stripe_account_attrs account
      create_stripe_account!(account_attrs)
    end
  end

  private

  def stripe_account_attrs account
    { stripe_user_id: account.id,
      secret_key: account.keys.secret,
      publishable_key: account.keys.publishable }
  end
end
