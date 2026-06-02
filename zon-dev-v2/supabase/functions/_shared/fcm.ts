// FCM HTTP v1 API — uses short-lived OAuth 2.0 tokens from a service account.
// Legacy server key deprecated June 2024.

/** Get a short-lived OAuth 2.0 access token from a service account. */
async function getAccessToken(
  clientEmail: string,
  privateKeyPem: string
): Promise<string> {
  const now = Math.floor(Date.now() / 1000)

  const header = { alg: 'RS256', typ: 'JWT' }
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  }

  const encode = (obj: object) =>
    btoa(JSON.stringify(obj))
      .replace(/=/g, '')
      .replace(/\+/g, '-')
      .replace(/\//g, '_')

  const signingInput = `${encode(header)}.${encode(payload)}`

  // Strip PEM headers and decode base64
  const pem = privateKeyPem.replace(/\\n/g, '\n')
  const pemBody = pem
    .replace('-----BEGIN PRIVATE KEY-----', '')
    .replace('-----END PRIVATE KEY-----', '')
    .replace(/\s/g, '')
  const keyBytes = Uint8Array.from(atob(pemBody), (c) => c.charCodeAt(0))

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    keyBytes,
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign']
  )

  const sigBytes = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(signingInput)
  )

  const signature = btoa(String.fromCharCode(...new Uint8Array(sigBytes)))
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_')

  const jwt = `${signingInput}.${signature}`

  // Exchange JWT for access token
  const tokenRes = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: jwt,
    }),
  })

  const tokenData = await tokenRes.json()
  if (!tokenData.access_token) {
    throw new Error(`FCM token exchange failed: ${JSON.stringify(tokenData)}`)
  }
  return tokenData.access_token as string
}

export interface FcmMessage {
  title: string
  body: string
  data?: Record<string, string>
}

/**
 * Send a push notification via FCM HTTP v1 API.
 * Returns true if the message was accepted by FCM.
 */
export async function sendFcmNotification(
  deviceToken: string,
  message: FcmMessage
): Promise<boolean> {
  const projectId = Deno.env.get('FIREBASE_PROJECT_ID')
  const clientEmail = Deno.env.get('FIREBASE_CLIENT_EMAIL')
  const privateKey = Deno.env.get('FIREBASE_PRIVATE_KEY')

  if (!projectId || !clientEmail || !privateKey) return false

  try {
    const accessToken = await getAccessToken(clientEmail, privateKey)

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${accessToken}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          message: {
            token: deviceToken,
            notification: {
              title: message.title,
              body: message.body,
            },
            data: message.data ?? {},
            apns: {
              payload: {
                aps: { sound: 'default', badge: 1 },
              },
            },
          },
        }),
      }
    )

    return res.ok
  } catch (err) {
    console.error('FCM send error:', err)
    return false
  }
}
