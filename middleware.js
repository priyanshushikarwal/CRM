import { NextResponse } from 'next/server';

// ==========================================
// CONFIGURATION FOR SUB-APPLICATION
// ==========================================
const APP_IDENTIFIER = 'crm'; // Change per app: 'live_tracking' | 'hrms' | 'crm'
const PORTAL_URL = 'https://dooninfra.in'; // Production URL of main portal
const LOCAL_PORTAL_URL = 'http://localhost:5173'; // Development fallback

export async function middleware(request) {
  const { nextUrl, cookies } = request;
  const { pathname } = nextUrl;

  // Immediately bypass for static assets to optimize performance and prevent intercepts on scripts/images
  if (
    pathname.includes('/assets/') ||
    pathname.includes('/canvaskit/') ||
    pathname.includes('/icons/') ||
    pathname.endsWith('.js') ||
    pathname.endsWith('.css') ||
    pathname.endsWith('.png') ||
    pathname.endsWith('.jpg') ||
    pathname.endsWith('.jpeg') ||
    pathname.endsWith('.svg') ||
    pathname.endsWith('.ico') ||
    pathname.endsWith('.json') ||
    pathname.endsWith('.wasm') ||
    pathname.endsWith('.map') ||
    pathname.endsWith('.txt')
  ) {
    return NextResponse.next();
  }
  
  // Detect environment
  const isLocal = nextUrl.hostname === 'localhost' || nextUrl.hostname === '127.0.0.1';
  const portalHost = isLocal ? LOCAL_PORTAL_URL : PORTAL_URL;

  const ssoToken = nextUrl.searchParams.get('sso_token');

  // 1. Handle incoming SSO Token redirection
  if (ssoToken) {
    try {
      const verifyUrl = `${portalHost}/api/verify-sso-token?sso_token=${encodeURIComponent(ssoToken)}&app=${APP_IDENTIFIER}`;
      const verifyResponse = await fetch(verifyUrl);

      if (!verifyResponse.ok) {
        throw new Error('SSO token verification failed');
      }

      const data = await verifyResponse.json();

      if (data.verified) {
        // Prepare redirect to strip token from the URL for cleaner UX and security
        const cleanUrl = nextUrl.clone();
        cleanUrl.searchParams.delete('sso_token');
        
        const response = NextResponse.redirect(cleanUrl);

        // Set secure, HTTP-only cookie representing verified DoonInfra status
        response.cookies.set('dooninfra_session', JSON.stringify({
          email: data.email,
          uid: data.uid,
          app: APP_IDENTIFIER,
          timestamp: Date.now()
        }), {
          httpOnly: true,
          secure: !isLocal,
          sameSite: 'lax',
          maxAge: 3600 // Valid for 1 hour
        });

        return response;
      }
    } catch (error) {
      console.error('[SSO Middleware] Verification error:', error);
      // Redirect to login with error parameter
      return NextResponse.redirect(`${portalHost}/login.html?redirect=${encodeURIComponent(request.url)}&app=${APP_IDENTIFIER}&error=auth_failed`);
    }
  }

  // 2. Check for active DoonInfra session cookie
  const sessionCookie = cookies.get('dooninfra_session');
  if (sessionCookie) {
    try {
      const session = JSON.parse(sessionCookie.value);
      const now = Date.now();
      
      // Allow if session matches app and is not expired (1 hour expiration)
      if (session.email && session.app === APP_IDENTIFIER && (now - session.timestamp < 3600000)) {
        return NextResponse.next(); // Allow request to proceed to the app's login page/routes
      }
    } catch (e) {
      // Clean invalid cookies
    }
  }

  // 3. Unauthenticated access -> Intercept and Redirect at the Edge Network
  const redirectTarget = `${portalHost}/login.html?redirect=${encodeURIComponent(request.url)}&app=${APP_IDENTIFIER}`;
  return NextResponse.redirect(redirectTarget);
}

// Config to run middleware on all routes except API and core assets to catch / and /index.html
export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
