require 'rails_helper'

RSpec.describe PostsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, username: 'otheruser', email: 'other@example.com') }
  let(:post_attributes) { attributes_for(:post) }
  let(:invalid_attributes) { { title: '', description: '' } }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(true)
  end

  describe "GET #index" do
    let!(:regular_post) { create(:post, user: user, post_type: :regular) }
    let!(:tutorial_post) { create(:post, user: user, post_type: :tutorial) }
    let!(:tag) { create(:tag, name: 'pottery') }

    before do
      regular_post.tags << tag
    end

    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns all published posts" do
      get :index
      expect(assigns(:posts)).to include(regular_post, tutorial_post)
    end

    it "filters by post type when specified" do
      get :index, params: { post_type: 'tutorial' }
      expect(assigns(:posts)).to include(tutorial_post)
      expect(assigns(:posts)).not_to include(regular_post)
    end

    it "filters by tag when specified" do
      get :index, params: { tag: 'pottery' }
      expect(assigns(:posts)).to include(regular_post)
      expect(assigns(:posts)).not_to include(tutorial_post)
    end

    it "sorts posts by popularity when requested" do
      # Create likes to make regular_post more popular
      create_list(:like, 3, post: regular_post)
      create(:like, post: tutorial_post)

      get :index, params: { sort: 'popular' }
      posts = assigns(:posts).to_a
      expect(posts.first).to eq(regular_post)
    end
  end

  describe "GET #show" do
    let(:post) { create(:post, user: user) }

    it "returns a success response" do
      get :show, params: { id: post.to_param }
      expect(response).to be_successful
    end

    it "assigns the requested post" do
      get :show, params: { id: post.to_param }
      expect(assigns(:post)).to eq(post)
    end

    it "assigns a new comment" do
      get :show, params: { id: post.to_param }
      expect(assigns(:comment)).to be_a_new(Comment)
    end
  end

  describe "GET #new" do
    it "returns a success response" do
      get :new
      expect(response).to be_successful
    end

    it "assigns a new post" do
      get :new
      expect(assigns(:post)).to be_a_new(Post)
    end
  end

  describe "GET #edit" do
    let(:post) { create(:post, user: user) }

    context "when user owns the post" do
      it "returns a success response" do
        get :edit, params: { id: post.to_param }
        expect(response).to be_successful
      end
    end

    context "when user does not own the post" do
      before do
        allow(controller).to receive(:current_user).and_return(other_user)
      end

      it "redirects to posts path" do
        get :edit, params: { id: post.to_param }
        expect(response).to redirect_to(posts_path)
      end

      it "sets an alert message" do
        get :edit, params: { id: post.to_param }
        expect(flash[:alert]).to eq('You are not authorized to perform this action.')
      end
    end
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new Post" do
        expect {
          post :create, params: { post: post_attributes }
        }.to change(Post, :count).by(1)
      end

      it "assigns the post to the current user" do
        post :create, params: { post: post_attributes }
        expect(assigns(:post).user).to eq(user)
      end

      it "redirects to the created post" do
        post :create, params: { post: post_attributes }
        expect(response).to redirect_to(Post.last)
      end

      it "adds tags when provided" do
        post :create, params: { 
          post: post_attributes, 
          post: { **post_attributes, tag_names: 'pottery, ceramic' }
        }
        created_post = Post.last
        expect(created_post.tags.pluck(:name)).to include('pottery', 'ceramic')
      end
    end

    context "with invalid parameters" do
      it "does not create a new Post" do
        expect {
          post :create, params: { post: invalid_attributes }
        }.to change(Post, :count).by(0)
      end

      it "renders the new template" do
        post :create, params: { post: invalid_attributes }
        expect(response).to render_template("new")
      end

      it "returns unprocessable entity status" do
        post :create, params: { post: invalid_attributes }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PUT #update" do
    let(:post) { create(:post, user: user) }
    let(:new_attributes) { { title: 'Updated Title', description: 'Updated description' } }

    context "when user owns the post" do
      context "with valid parameters" do
        it "updates the requested post" do
          put :update, params: { id: post.to_param, post: new_attributes }
          post.reload
          expect(post.title).to eq('Updated Title')
          expect(post.description).to eq('Updated description')
        end

        it "redirects to the post" do
          put :update, params: { id: post.to_param, post: new_attributes }
          expect(response).to redirect_to(post)
        end

        it "updates tags when provided" do
          put :update, params: { 
            id: post.to_param, 
            post: new_attributes,
            post: { **new_attributes, tag_names: 'newtag, updated' }
          }
          post.reload
          expect(post.tags.pluck(:name)).to include('newtag', 'updated')
        end
      end

      context "with invalid parameters" do
        it "renders the edit template" do
          put :update, params: { id: post.to_param, post: invalid_attributes }
          expect(response).to render_template("edit")
        end

        it "returns unprocessable entity status" do
          put :update, params: { id: post.to_param, post: invalid_attributes }
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end

    context "when user does not own the post" do
      before do
        allow(controller).to receive(:current_user).and_return(other_user)
      end

      it "redirects to posts path" do
        put :update, params: { id: post.to_param, post: new_attributes }
        expect(response).to redirect_to(posts_path)
      end

      it "does not update the post" do
        original_title = post.title
        put :update, params: { id: post.to_param, post: new_attributes }
        post.reload
        expect(post.title).to eq(original_title)
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:post) { create(:post, user: user) }

    context "when user owns the post" do
      it "destroys the requested post" do
        expect {
          delete :destroy, params: { id: post.to_param }
        }.to change(Post, :count).by(-1)
      end

      it "redirects to the posts list" do
        delete :destroy, params: { id: post.to_param }
        expect(response).to redirect_to(posts_path)
      end
    end

    context "when user does not own the post" do
      before do
        allow(controller).to receive(:current_user).and_return(other_user)
      end

      it "does not destroy the post" do
        expect {
          delete :destroy, params: { id: post.to_param }
        }.to change(Post, :count).by(0)
      end

      it "redirects to posts path" do
        delete :destroy, params: { id: post.to_param }
        expect(response).to redirect_to(posts_path)
      end
    end
  end

  describe "POST #like" do
    let(:post) { create(:post, user: other_user) }

    it "toggles like status" do
      expect {
        post :like, params: { id: post.to_param }, format: :json
      }.to change { post.likes.count }.by(1)
    end

    it "returns JSON response with like status" do
      post :like, params: { id: post.to_param }, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response['liked']).to be true
      expect(json_response['likes_count']).to eq(1)
    end

    it "unlikes when already liked" do
      create(:like, post: post, user: user)
      
      expect {
        post :like, params: { id: post.to_param }, format: :json
      }.to change { post.likes.count }.by(-1)
    end
  end
end