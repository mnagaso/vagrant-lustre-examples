// Define a more specific interface for auth data
interface AuthData {
  token?: string;
  message?: string;
  userId?: string;
  requirePasswordChange?: boolean;
  error?: string;
  code?: string;
  [key: string]: unknown; // For any additional properties
}

export type AuthResponse = {
  success: boolean;
  response?: Response;
  data?: AuthData;
};

export const useAuth = () => {
  const login = async (username: string, password: string): Promise<AuthResponse> => {
    try {
      // console out everything to the console for debugging
      console.log('Login request:', { username, password });

      const response = await fetch('/api/auth', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ username, password }),
        credentials: 'include'
      });

      const data = await response.json();

      console.log(`AUTH RESPONSE - Status: ${response.status}`, {
        statusText: response.statusText,
        headers: Object.fromEntries([...response.headers.entries()]),
        data
      });

      return {
        success: response.ok,
        response,
        data
      };
    } catch (error) {
      console.error('Login request failed:', error);
      return { success: false };
    }
  };

  const detectRateLimit = (response: Response, errorMsg: string): boolean => {
    // 1. Check status code (429 is standard for rate limiting)
    if (response.status === 429) return true;

    // 2. Check common rate limiting keywords in the error message
    const rateLimitKeywords = [
      'rate limit', 'rate-limit', 'ratelimit',
      'too many', 'too fast', 'slow down',
      'try again later', 'try later',
      'exceeded', 'throttle', 'throttled'
    ];

    if (typeof errorMsg === 'string') {
      const lowerMsg = errorMsg.toLowerCase();
      return rateLimitKeywords.some(keyword => lowerMsg.includes(keyword));
    }

    // 3. Check for Retry-After header
    if (response.headers.has('Retry-After')) return true;

    // 4. Check for specific error codes
    if (response.status === 429) return true;

    return false;
  };

  const formatErrorMessage = (
    response: Response,
    errorMsg: string,
    isRateLimited: boolean
  ): string => {
    if (isRateLimited) {
      const retryAfter = response.headers.get('Retry-After') || '60';
      const waitTime = parseInt(retryAfter, 10);

      return `Too many login attempts. Please try again ${
        waitTime > 60
          ? `in ${Math.ceil(waitTime / 60)} minute${Math.ceil(waitTime / 60) > 1 ? 's' : ''}`
          : `after ${waitTime} second${waitTime !== 1 ? 's' : ''}`
      }.`;
    }

    if (response.status === 401) {
      return 'Invalid username or password';
    }

    if (response.status === 403) {
      return 'Account is locked. Please contact an administrator';
    }

    if (response.status >= 500) {
      return 'Server error. Please try again later';
    }

    return errorMsg;
  };

  return {
    login,
    detectRateLimit,
    formatErrorMessage
  };
};
