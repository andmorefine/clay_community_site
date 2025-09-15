class SpamDetectionService
  SPAM_KEYWORDS = [
    'buy now', 'click here', 'free money', 'get rich quick', 'make money fast',
    'viagra', 'casino', 'lottery', 'winner', 'congratulations you won',
    'urgent', 'act now', 'limited time', 'special offer', 'discount',
    'http://', 'https://', 'www.', '.com', '.net', '.org'
  ].freeze
  
  SUSPICIOUS_PATTERNS = [
    /\b\d{10,}\b/, # Long numbers (phone numbers, etc.)
    /[A-Z]{5,}/, # All caps words
    /(.)\1{4,}/, # Repeated characters
    /@\w+\.(com|net|org|info)/, # Email addresses
    /\$\d+/, # Money amounts
  ].freeze
  
  def self.check_content(content)
    return { spam: false, score: 0, reasons: [] } if content.blank?
    
    content = content.to_s.downcase
    score = 0
    reasons = []
    
    # Check for spam keywords
    SPAM_KEYWORDS.each do |keyword|
      if content.include?(keyword)
        score += keyword.include?('http') ? 3 : 2
        reasons << "Contains spam keyword: #{keyword}"
      end
    end
    
    # Check for suspicious patterns
    SUSPICIOUS_PATTERNS.each_with_index do |pattern, index|
      if content.match?(pattern)
        score += 2
        case index
        when 0
          reasons << "Contains suspicious number pattern"
        when 1
          reasons << "Contains excessive capital letters"
        when 2
          reasons << "Contains repeated characters"
        when 3
          reasons << "Contains email address"
        when 4
          reasons << "Contains money amounts"
        end
      end
    end
    
    # Check for excessive links
    link_count = content.scan(/https?:\/\//).length
    if link_count > 2
      score += link_count * 2
      reasons << "Contains multiple links (#{link_count})"
    end
    
    # Check for excessive punctuation
    exclamation_count = content.count('!')
    if exclamation_count > 3
      score += exclamation_count
      reasons << "Excessive exclamation marks (#{exclamation_count})"
    end
    
    # Determine if it's spam based on score
    is_spam = score >= 5
    
    {
      spam: is_spam,
      score: score,
      reasons: reasons,
      confidence: calculate_confidence(score)
    }
  end
  
  def self.check_user_behavior(user)
    return { suspicious: false, score: 0, reasons: [] } unless user
    
    score = 0
    reasons = []
    
    # Check posting frequency
    recent_posts = user.posts.where('created_at > ?', 1.hour.ago).count
    if recent_posts > 5
      score += recent_posts * 2
      reasons << "High posting frequency (#{recent_posts} posts in last hour)"
    end
    
    # Check comment frequency
    recent_comments = user.comments.where('created_at > ?', 1.hour.ago).count
    if recent_comments > 10
      score += recent_comments
      reasons << "High commenting frequency (#{recent_comments} comments in last hour)"
    end
    
    # Check account age
    if user.created_at > 1.day.ago
      score += 3
      reasons << "New account (created #{time_ago_in_words(user.created_at)} ago)"
    end
    
    # Check warning count
    if user.warning_count > 0
      score += user.warning_count * 2
      reasons << "Previous warnings (#{user.warning_count})"
    end
    
    {
      suspicious: score >= 7,
      score: score,
      reasons: reasons,
      confidence: calculate_confidence(score)
    }
  end
  
  def self.auto_moderate_content(content, user)
    content_check = check_content(content.is_a?(String) ? content : extract_text_content(content))
    user_check = check_user_behavior(user)
    
    total_score = content_check[:score] + user_check[:score]
    
    if total_score >= 10 || content_check[:spam]
      # Auto-flag for review
      create_auto_report(content, content_check, user_check)
      return { action: 'flagged', score: total_score }
    elsif total_score >= 7
      # Require manual review
      return { action: 'review_required', score: total_score }
    else
      return { action: 'approved', score: total_score }
    end
  end
  
  private
  
  def self.calculate_confidence(score)
    case score
    when 0..2
      'low'
    when 3..6
      'medium'
    when 7..10
      'high'
    else
      'very_high'
    end
  end
  
  def self.extract_text_content(content)
    case content
    when Post
      "#{content.title} #{content.description}"
    when Comment
      content.content
    when User
      "#{content.username} #{content.bio}"
    else
      content.to_s
    end
  end
  
  def self.create_auto_report(content, content_check, user_check)
    # Create a system report for auto-detected spam
    system_user = User.find_by(role: 'admin') || User.first
    return unless system_user
    
    reasons = (content_check[:reasons] + user_check[:reasons]).join('; ')
    
    Report.create!(
      user: system_user,
      reportable: content,
      reason: 'Automatic spam detection',
      description: "Auto-detected potential spam. Score: #{content_check[:score] + user_check[:score]}. Reasons: #{reasons}",
      status: 'pending'
    )
  end
  
  def self.time_ago_in_words(time)
    # Simple time ago implementation
    diff = Time.current - time
    case diff
    when 0..59
      "#{diff.to_i} seconds"
    when 60..3599
      "#{(diff / 60).to_i} minutes"
    when 3600..86399
      "#{(diff / 3600).to_i} hours"
    else
      "#{(diff / 86400).to_i} days"
    end
  end
end