class Events::GoaledEvent < Events::RegularEvent
  validates :product_id, uniqueness: true

  def self.trigger product
    create(product: product, created_at: product.goaled_at)
      .tap(&:deliver_to_seller)
      .tap(&:deliver_to_user)
  end
end
