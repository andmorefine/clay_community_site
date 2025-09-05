require 'rails_helper'

RSpec.describe CommentsController, type: :controller do
  let(:user) { create(:user) }
  let(:other_user) { create(:user, username: 'otheruser', email: 'other@example.com') }
  let(:post) { create(:post, user: other_user) }
  let(:comment_attributes) { { content: 'Great work!' } }
  let(:invalid_attributes) { { content: '' } }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    allow(controller).to receive(:user_signed_in?).and_return(true)
  end

  describe "POST #create" do
    context "with valid parameters" do
      it "creates a new Comment" do
        expect {
          post :create, params: { post_id: post.to_param, comment: comment_attributes }
        }.to change(Comment, :count).by(1)
      end

      it "assigns the comment to the current user" do
        post :create, params: { post_id: post.to_param, comment: comment_attributes }
        expect(Comment.last.user).to eq(user)
      end

      it "assigns the comment to the correct post" do
        post :create, params: { post_id: post.to_param, comment: comment_attributes }
        expect(Comment.last.post).to eq(post)
      end

      it "redirects to the post" do
        post :create, params: { post_id: post.to_param, comment: comment_attributes }
        expect(response).to redirect_to(post)
      end

      it "sets a success notice" do
        post :create, params: { post_id: post.to_param, comment: comment_attributes }
        expect(flash[:notice]).to eq('Comment was successfully added.')
      end
    end

    context "with invalid parameters" do
      it "does not create a new Comment" do
        expect {
          post :create, params: { post_id: post.to_param, comment: invalid_attributes }
        }.to change(Comment, :count).by(0)
      end

      it "redirects to the post with an alert" do
        post :create, params: { post_id: post.to_param, comment: invalid_attributes }
        expect(response).to redirect_to(post)
        expect(flash[:alert]).to eq('Unable to add comment. Please try again.')
      end
    end
  end

  describe "DELETE #destroy" do
    let!(:comment) { create(:comment, post: post, user: user) }

    context "when user owns the comment" do
      it "destroys the requested comment" do
        expect {
          delete :destroy, params: { post_id: post.to_param, id: comment.to_param }
        }.to change(Comment, :count).by(-1)
      end

      it "redirects to the post" do
        delete :destroy, params: { post_id: post.to_param, id: comment.to_param }
        expect(response).to redirect_to(post)
      end

      it "sets a success notice" do
        delete :destroy, params: { post_id: post.to_param, id: comment.to_param }
        expect(flash[:notice]).to eq('Comment was successfully deleted.')
      end
    end

    context "when user does not own the comment" do
      let!(:other_comment) { create(:comment, post: post, user: other_user) }

      before do
        allow(controller).to receive(:current_user).and_return(user)
      end

      it "does not destroy the comment" do
        expect {
          delete :destroy, params: { post_id: post.to_param, id: other_comment.to_param }
        }.to change(Comment, :count).by(0)
      end

      it "redirects to the post with an alert" do
        delete :destroy, params: { post_id: post.to_param, id: other_comment.to_param }
        expect(response).to redirect_to(post)
        expect(flash[:alert]).to eq('You are not authorized to delete this comment.')
      end
    end
  end

  describe "authorization" do
    context "when user is not signed in" do
      before do
        allow(controller).to receive(:user_signed_in?).and_return(false)
      end

      it "redirects to sign in page for create action" do
        post :create, params: { post_id: post.to_param, comment: comment_attributes }
        expect(response).to redirect_to(new_user_session_path)
      end

      it "redirects to sign in page for destroy action" do
        comment = create(:comment, post: post, user: user)
        delete :destroy, params: { post_id: post.to_param, id: comment.to_param }
        expect(response).to redirect_to(new_user_session_path)
      end
    end
  end
end