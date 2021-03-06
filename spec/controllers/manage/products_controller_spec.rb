require 'rails_helper'

shared_examples_for Manage::ProductsController do
  let(:invalid_attributes) { { title: nil } }

  describe 'GET #show' do
    it 'assings events for product' do
      product.pictures = [FactoryGirl.create(:picture)]
      product.update started_at: Time.current
      FactoryGirl.create_list(:bid, 2, product: product)
      get :show, { id: product.id }
      expect(assigns(:events).count).to eq 3
      expect(assigns(:events)).to eq product.events
    end
  end

  describe 'GET #new' do
    it 'assigns a new product as @product' do
      get :new
      expect(assigns(:product)).to be_a_new(Product)
    end
  end

  describe 'GET #edit' do
    it 'assigns the requested product as @product' do
      get :edit, { id: product.to_param }
      expect(assigns(:product)).to eq(product)
    end
  end

  describe 'POST #create' do
    context 'with valid params' do
      let(:valid_attributes) {
        {
          title: 'Product',
          price: 1000,
          goal: 10,
          external_url: 'http://store.wonder_cat_factory.test/'
        }
      }

      it 'creates a new Product' do
        expect {
          post :create, { product: valid_attributes }
        }.to change(Product, :count).by(1)
      end

      it 'assigns a newly created product as @product' do
        post :create, { product: valid_attributes }
        expect(assigns(:product)).to be_a(Product)
        expect(assigns(:product)).to be_persisted
      end

      it 'sets user as current_user' do
        post :create, { product: valid_attributes }
        product = assigns(:product)
        expect(product.user).to eq @current_user
      end

      it 'redirects to the created product' do
        post :create, { product: valid_attributes }
        expect(response).to redirect_to([:edit, role, Product.last])
      end
    end

    context 'with invalid params' do
      it 'assigns a newly created but unsaved product as @product' do
        post :create, { product: invalid_attributes }
        expect(assigns(:product)).to be_a_new(Product)
      end

      it "re-renders the 'new' template" do
        post :create, { product: invalid_attributes }
        expect(response).to render_template('new')
      end
    end
  end

  describe 'PUT #update' do
    context 'with valid params' do
      let(:new_attributes) {
        {
          title: 'New Title',
          external_url: 'http://store.wonder_cat_factory.test/'
        }
      }

      it 'updates the requested product' do
        put :update, { id: product.to_param, product: new_attributes }
        product.reload
        expect(product.title).to eq 'New Title'
      end

      it 'assigns the requested product as @product' do
        put :update, { id: product.to_param, product: new_attributes }
        expect(assigns(:product)).to eq(product)
      end

      it 'redirects to the product' do
        put :update, { id: product.to_param, product: new_attributes }
        expect(response).to redirect_to([:edit, role, product])
      end
    end

    context 'with invalid params' do
      it 'assigns the product as @product' do
        put :update, { id: product.to_param, product: invalid_attributes }
        expect(assigns(:product)).to eq(product)
      end

      it "re-renders the 'edit' template" do
        put :update, { id: product.to_param, product: invalid_attributes }
        expect(response).to render_template('edit')
      end
    end
  end

  describe 'DELETE #destroy' do
    it 'destroys the requested product' do
      product
      expect {
        delete :destroy, { id: product.to_param }
      }.to change(Product, :count).by(-1)
    end

    it 'redirects to the products list' do
      delete :destroy, { id: product.to_param }
      expect(response).to redirect_to([role, :products])
    end
  end

  describe 'POST #start' do
    context 'with non-started product' do
      before do
        product.pictures = [FactoryGirl.create(:picture)]
      end

      it 'sets started_at' do
        expect {
          post :start, { id: product.id }
        }.to change { product.reload.started_at? }.from(false).to(true)
      end

      it 'creates StartedEvent' do
        expect {
          post :start, { id: product.id }
        }.to change(Events::StartedEvent, :count).by(1)
        event = Events::StartedEvent.last
        expect(event.product_id).to eq product.id
      end
    end

    context 'with non-started product without picture' do
      it 'fails to set started_at' do
        expect {
          post :start, { id: product.id }
        }.not_to change { product.reload.started_at }
      end
    end

    context 'with started product' do
      before do
        product.pictures = [FactoryGirl.create(:picture)]
        product.update started_at: Time.current
      end

      it 'skips to set started_at' do
        expect {
          post :start, { id: product.id }
        }.not_to change { product.reload.started_at }
      end
    end

    context 'with non-started product without stripe_account user' do
      before do
        product.user.stripe_account = nil
      end
      it 'fails to set started_at' do
        expect {
          post :start, { id: product.id }
        }.not_to change { product.reload.started_at }
      end
    end
  end

  describe 'POST #accept' do
    context 'with goaled product' do
      before do
        product.update goaled_at: Time.current
      end

      it 'sets Bid#accepted_at for requested count' do
        bids = FactoryGirl.create_list(:bid, 2, product: product)
        FactoryGirl.create(:bid, product: product)
        expect {
          post :accept, { id: product.id, count: 2 }
        }.to change(Bid.accepted, :count).by(2)
        expect(Bid.accepted.sort).to eq bids
      end
    end

    context 'with non-goaled product' do
      it 'skips to set accepted_at' do
        FactoryGirl.create_list(:bid, 2, product: product)
        expect {
          post :accept, { id: product.id, count: 2 }
        }.not_to change(Bid.accepted, :count)
      end
    end
  end
end

RSpec.describe Admin::ProductsController, type: :controller do
  login_admin
  let(:role) { :admin }
  let(:product) {
    FactoryGirl.create(
      :product, user: FactoryGirl.create(:user, :with_stripe_account)
    )
  }
  it_behaves_like Manage::ProductsController
end

RSpec.describe Seller::ProductsController, type: :controller do
  login_seller
  let(:role) { :seller }
  let(:product) { FactoryGirl.create(:product, user: @current_user) }
  it_behaves_like Manage::ProductsController
end
