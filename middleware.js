// ==========================================
// CONFIGURATION FOR SUB-APPLICATION
// ==========================================
const APP_IDENTIFIER = 'crm'; // Change per app: 'live_tracking' | 'hrms' | 'crm'
const PORTAL_URL = 'https://dooninfra.in'; // Production URL of main portal
const LOCAL_PORTAL_URL = 'http://localhost:5173'; // Development fallback

export async function middleware(request) {
  const url = new URL(request.url);
  const { pathname, searchParams } = url;

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
    return new Response(null, {
      headers: { 'x-middleware-next': '1' }
    });
  }

  // Detect environment
  const isLocal = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
  const portalHost = isLocal ? LOCAL_PORTAL_URL : PORTAL_URL;

  const ssoToken = searchParams.get('sso_token');

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
        // Strip token from the URL for cleaner UX and security
        const cleanUrl = new URL(request.url);
        cleanUrl.searchParams.delete('sso_token');

        const sessionData = {
          email: data.email,
          uid: data.uid,
          app: APP_IDENTIFIER,
          timestamp: Date.now()
        };

        const cookieValue = encodeURIComponent(JSON.stringify(sessionData));
        const cookieOptions = `dooninfra_session=${cookieValue}; Path=/; Max-Age=3600; SameSite=Lax; HttpOnly${isLocal ? '' : '; Secure'}`;

        return new Response(null, {
          status: 307,
          headers: {
            'Location': cleanUrl.toString(),
            'Set-Cookie': cookieOptions
          }
        });
      }
    } catch (error) {
      console.error('[SSO Middleware] Verification error:', error);
      // Redirect to login with error parameter
      return Response.redirect(`${portalHost}/login.html?redirect=${encodeURIComponent(request.url)}&app=${APP_IDENTIFIER}&error=auth_failed`, 307);
    }
  }

  // 2. Check for active DoonInfra session cookie
  const cookieHeader = request.headers.get('cookie') || '';
  const cookies = {};
  cookieHeader.split(';').forEach(c => {
    const parts = c.split('=');
    if (parts.length >= 2) {
      cookies[parts[0].trim()] = parts.slice(1).join('=').trim();
    }
  });

  const sessionCookieVal = cookies['dooninfra_session'];
  if (sessionCookieVal) {
    try {
      const session = JSON.parse(decodeURIComponent(sessionCookieVal));
      const now = Date.now();
      
      // Allow if session matches app and is not expired (1 hour expiration)
      if (session.email && session.app === APP_IDENTIFIER && (now - session.timestamp < 3600000)) {
        return new Response(null, {
          headers: { 'x-middleware-next': '1' }
        });
      }
    } catch (e) {
      // Clean invalid cookies
    }
  }

  // 3. Unauthenticated access -> Intercept and Redirect at the Edge Network
  const redirectTarget = `${portalHost}/login.html?redirect=${encodeURIComponent(request.url)}&app=${APP_IDENTIFIER}`;
  return Response.redirect(redirectTarget, 307);
}

// Config to run middleware on all routes except API and core assets to catch / and /index.html
export const config = {
  matcher: [
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
};
