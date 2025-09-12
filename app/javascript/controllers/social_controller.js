import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="social"
export default class extends Controller {
  static targets = ["likeButton", "likeIcon", "likeCount", "commentForm", "commentsList"]
  static values = { 
    postId: Number,
    liked: Boolean,
    likesCount: Number
  }

  connect() {
    this.updateLikeButton()
  }

  // Like/Unlike functionality
  async toggleLike(event) {
    event.preventDefault()
    
    const button = this.likeButtonTarget
    const originalState = this.likedValue
    const originalCount = this.likesCountValue
    
    // Optimistic update
    this.likedValue = !this.likedValue
    this.likesCountValue += this.likedValue ? 1 : -1
    this.updateLikeButton()
    
    try {
      // Use the new likes endpoint with proper HTTP methods
      const url = this.likedValue 
        ? `/posts/${this.postIdValue}/likes`
        : `/posts/${this.postIdValue}/likes/1` // We'll need to get the actual like ID
      
      const method = this.likedValue ? 'POST' : 'DELETE'
      
      // For simplicity, let's use the existing like endpoint for now
      const response = await fetch(`/posts/${this.postIdValue}/like`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      
      const data = await response.json()
      
      // Update with server response
      this.likedValue = data.liked
      this.likesCountValue = data.likes_count
      this.updateLikeButton()
      
      // Show success message
      this.showNotification(data.liked ? 'Post liked!' : 'Post unliked!', 'success')
      
    } catch (error) {
      console.error('Error toggling like:', error)
      
      // Revert optimistic update on error
      this.likedValue = originalState
      this.likesCountValue = originalCount
      this.updateLikeButton()
      
      // Show error message
      this.showNotification('Failed to update like. Please try again.', 'error')
    }
  }

  // Update like button appearance
  updateLikeButton() {
    if (this.hasLikeIconTarget && this.hasLikeCountTarget) {
      this.likeIconTarget.textContent = this.likedValue ? '❤️' : '🤍'
      this.likeCountTarget.textContent = this.likesCountValue
      
      // Update button styling
      const button = this.likeButtonTarget
      if (this.likedValue) {
        button.classList.add('text-red-600')
        button.classList.remove('text-gray-600')
      } else {
        button.classList.add('text-gray-600')
        button.classList.remove('text-red-600')
      }
    }
  }

  // Comment form submission
  async submitComment(event) {
    event.preventDefault()
    
    const form = event.target
    const formData = new FormData(form)
    const submitButton = form.querySelector('input[type="submit"]')
    const originalButtonText = submitButton.value
    
    // Disable submit button
    submitButton.disabled = true
    submitButton.value = 'Posting...'
    
    try {
      const response = await fetch(form.action, {
        method: 'POST',
        body: formData,
        headers: {
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        // Clear form
        form.reset()
        
        // Reload comments section (you could make this more sophisticated)
        window.location.reload()
        
      } else {
        throw new Error('Failed to post comment')
      }
      
    } catch (error) {
      console.error('Error posting comment:', error)
      this.showNotification('Failed to post comment. Please try again.', 'error')
      
    } finally {
      // Re-enable submit button
      submitButton.disabled = false
      submitButton.value = originalButtonText
    }
  }

  // Delete comment
  async deleteComment(event) {
    event.preventDefault()
    
    if (!confirm('Are you sure you want to delete this comment?')) {
      return
    }
    
    const link = event.target.closest('a')
    const commentElement = event.target.closest('.comment-item')
    
    try {
      const response = await fetch(link.href, {
        method: 'DELETE',
        headers: {
          'X-CSRF-Token': this.getCSRFToken()
        }
      })
      
      if (response.ok) {
        // Remove comment from DOM with animation
        if (commentElement) {
          commentElement.style.transition = 'opacity 0.3s ease'
          commentElement.style.opacity = '0'
          setTimeout(() => {
            commentElement.remove()
            this.updateCommentsCount(-1)
          }, 300)
        }
        
        this.showNotification('Comment deleted successfully', 'success')
        
      } else {
        throw new Error('Failed to delete comment')
      }
      
    } catch (error) {
      console.error('Error deleting comment:', error)
      this.showNotification('Failed to delete comment. Please try again.', 'error')
    }
  }

  // Update comments count in UI
  updateCommentsCount(delta) {
    const commentsCountElements = document.querySelectorAll('[data-comments-count]')
    commentsCountElements.forEach(element => {
      const currentCount = parseInt(element.textContent) || 0
      element.textContent = Math.max(0, currentCount + delta)
    })
  }

  // Utility methods
  getCSRFToken() {
    const token = document.querySelector('[name="csrf-token"]')
    return token ? token.content : ''
  }

  showNotification(message, type = 'info') {
    // Create a simple notification
    const notification = document.createElement('div')
    notification.className = `fixed top-4 right-4 z-50 px-4 py-2 rounded-lg text-white font-medium transition-all duration-300 ${
      type === 'error' ? 'bg-red-500' : type === 'success' ? 'bg-green-500' : 'bg-blue-500'
    }`
    notification.textContent = message
    
    document.body.appendChild(notification)
    
    // Animate in
    setTimeout(() => {
      notification.style.transform = 'translateX(0)'
      notification.style.opacity = '1'
    }, 10)
    
    // Remove after 3 seconds
    setTimeout(() => {
      notification.style.transform = 'translateX(100%)'
      notification.style.opacity = '0'
      setTimeout(() => {
        if (notification.parentNode) {
          notification.parentNode.removeChild(notification)
        }
      }, 300)
    }, 3000)
  }

  // Real-time updates (placeholder for future WebSocket integration)
  setupRealTimeUpdates() {
    // This could be enhanced with ActionCable for real-time updates
    // For now, we'll use polling as a fallback
    if (this.postIdValue) {
      this.pollForUpdates()
    }
  }

  pollForUpdates() {
    // Poll every 30 seconds for updates
    setInterval(async () => {
      try {
        const response = await fetch(`/posts/${this.postIdValue}/quick_view`, {
          headers: {
            'Accept': 'application/json'
          }
        })
        
        if (response.ok) {
          const data = await response.json()
          
          // Update likes count if changed
          if (data.likes_count !== this.likesCountValue) {
            this.likesCountValue = data.likes_count
            this.updateLikeButton()
          }
          
          // Update comments count
          const commentsCountElements = document.querySelectorAll('[data-comments-count]')
          commentsCountElements.forEach(element => {
            element.textContent = data.comments_count
          })
        }
      } catch (error) {
        console.error('Error polling for updates:', error)
      }
    }, 30000) // 30 seconds
  }
}