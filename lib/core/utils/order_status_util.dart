/// Order Status Utility
/// 
/// Handles status normalization, prioritization, and categorization
/// for consistent order management across the application.
class OrderStatusUtil {
  /// Normalized status categories
  static const String statusPending = 'Pending';
  static const String statusProcessing = 'In Progress';
  static const String statusShipped = 'Shipped';
  static const String statusCompleted = 'Done';
  static const String statusCancelled = 'Cancelled';

  /// Normalize various backend status strings to standard categories
  static String normalizeStatus(String? rawStatus) {
    if (rawStatus == null || rawStatus.isEmpty) return statusPending;
    
    final status = rawStatus.toLowerCase().trim();
    
    // Pending variants
    if (status == 'pending' || status == 'new' || status == 'awaiting') {
      return statusPending;
    }
    
    // Processing variants
    if (status == 'processing' || 
        status == 'in progress' || 
        status == 'confirmed' ||
        status == 'preparing' ||
        status == 'inprogress') {
      return statusProcessing;
    }
    
    // Shipped variants
    if (status == 'shipped' || 
        status == 'dispatched' || 
        status == 'in transit' ||
        status == 'out for delivery') {
      return statusShipped;
    }
    
    // Completed variants
    if (status == 'completed' || 
        status == 'delivered' || 
        status == 'received' ||
        status == 'fulfilled' ||
        status == 'done') {
      return statusCompleted;
    }
    
    // Cancelled variants
    if (status == 'cancelled' || 
        status == 'canceled' || 
        status == 'rejected' ||
        status == 'failed') {
      return statusCancelled;
    }
    
    // Default: return as-is with proper casing
    return rawStatus[0].toUpperCase() + rawStatus.substring(1).toLowerCase();
  }

  /// Get priority for sorting (1 = highest priority, 5 = lowest)
  static int getStatusPriority(String? status) {
    final normalized = normalizeStatus(status);
    
    switch (normalized) {
      case statusPending:
        return 1; // Show first - needs immediate attention
      case statusProcessing:
        return 2; // Show second - currently being worked on
      case statusShipped:
        return 3; // Show third - in transit
      case statusCompleted:
        return 4; // Show fourth - completed successfully
      case statusCancelled:
        return 5; // Show last - no action needed
      default:
        return 6; // Unknown statuses go to end
    }
  }

  /// Check if status is an "active" order (requires attention/tracking)
  static bool isActiveStatus(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusPending || 
           normalized == statusProcessing || 
           normalized == statusShipped;
  }

  /// Check if status is "completed" (successfully finished)
  static bool isCompletedStatus(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusCompleted;
  }

  /// Check if status is "failed" (cancelled/rejected)
  static bool isFailedStatus(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusCancelled;
  }

  /// Get status category for dashboard grouping
  static String getStatusCategory(String? status) {
    final normalized = normalizeStatus(status);
    
    if (normalized == statusPending) return 'Pending';
    if (normalized == statusProcessing || normalized == statusShipped) {
      return 'In Progress';
    }
    if (normalized == statusCompleted) return 'Done';
    if (normalized == statusCancelled) return 'Cancelled';
    
    return 'Other';
  }

  /// Check if status is "pending"
  static bool isPending(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusPending;
  }
  
  /// Check if status is "processing"
  static bool isProcessing(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusProcessing;
  }
  
  /// Check if status is "ready" (completed/received)
  static bool isReady(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusCompleted;
  }
  
    /// Check if status is "shipped"
  static bool isShipped(String? status) {
    final normalized = normalizeStatus(status);
    return normalized == statusShipped;
  }

  /// Compare two orders for sorting by status priority, then by date
  static int compareOrders(
    Map<String, dynamic> a, 
    Map<String, dynamic> b,
  ) {
    // First, compare by status priority
    final priorityA = getStatusPriority(a['status']);
    final priorityB = getStatusPriority(b['status']);
    
    if (priorityA != priorityB) {
      return priorityA.compareTo(priorityB); // Lower priority number = higher importance
    }
    
    // If same priority, sort by date (newest first)
    final dateA = a['sortDate'] as DateTime? ?? DateTime(2000);
    final dateB = b['sortDate'] as DateTime? ?? DateTime(2000);
    
    return dateB.compareTo(dateA); // Descending (newest first)
  }

  /// Get all available status filters for UI
  static List<String> getStatusFilters() {
    return [
      'All',
      statusPending,
      statusProcessing,
      statusShipped,
      statusCompleted,
      statusCancelled,
    ];
  }
}
