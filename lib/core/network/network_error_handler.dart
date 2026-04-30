import 'package:dio/dio.dart';

/// Enhanced error handling utility for network requests
class NetworkErrorHandler {
  static String getUserFriendlyMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Connection timeout. Please check your internet connection and try again.';
        
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Session expired. Please login again.';
          } else if (statusCode == 403) {
            return 'Access denied. Please check your permissions.';
          } else if (statusCode == 404) {
            return 'Resource not found. Please contact support.';
          } else if (statusCode == 500) {
            return 'Server error. Please try again later.';
          } else if (statusCode != null && statusCode >= 400 && statusCode < 500) {
            return 'Invalid request. Please check your input.';
          } else if (statusCode != null && statusCode >= 500) {
            return 'Server is currently unavailable. Please try again later.';
          }
          return 'An unexpected error occurred. Please try again.';
        
        case DioExceptionType.cancel:
          return 'Request was cancelled.';
        
        case DioExceptionType.badCertificate:
          return 'Security certificate error. Please check your connection.';
        
        case DioExceptionType.connectionError:
          return 'No internet connection. Please check your network settings.';
        
        case DioExceptionType.unknown:
          if (error.message?.contains('SocketException') ?? false) {
            return 'No internet connection. Please check your network settings.';
          }
          if (error.message?.contains('Failed host lookup') ?? false) {
            return 'Cannot reach server. Please check your internet connection.';
          }
          return 'Network error. Please check your connection and try again.';
      }
    }
    
    return 'An unexpected error occurred. Please try again.';
  }

  static bool isNetworkError(dynamic error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          (error.message?.contains('SocketException') ?? false) ||
          (error.message?.contains('Failed host lookup') ?? false);
    }
    return false;
  }

  static bool shouldRetry(dynamic error) {
    if (error is DioException) {
      // Retry on timeout and connection errors
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError;
    }
    return false;
  }
}
