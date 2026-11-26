'use strict';

const crypto = require('node:crypto');

const SUPPORTED_METHODS = ['card', 'fpx', 'grabpay'];

class PaymentError extends Error {
  constructor(message, { status = 502, code = 'payment_provider_error' } = {}) {
    super(message);
    this.status = status;
    this.code = code;
  }
}

class WebhookSignatureError extends Error {}

function encodeForm(value, prefix = '', out = []) {
  if (value === null || value === undefined) return out;
  if (Array.isArray(value)) {
    value.forEach((v, i) => encodeForm(v, `${prefix}[${i}]`, out));
  } else if (typeof value === 'object') {
    for (const [k, v] of Object.entries(value)) encodeForm(v, prefix ? `${prefix}[${k}]` : k, out);
  } else {
    out.push([prefix, String(value)]);
  }
  return out;
}

const toFormBody = (obj) => new URLSearchParams(encodeForm(obj)).toString();

function signWebhookPayload(secret, rawBody, timestampSec) {
  const sig = crypto.createHmac('sha256', secret).update(`${timestampSec}.${rawBody}`).digest('hex');
  return `t=${timestampSec},v1=${sig}`;
}

class StripeGateway {
  constructor({ secretKey, webhookSecret, fetchImpl = globalThis.fetch, apiBase = 'https://api.stripe.com' }) {
    if (!secretKey) throw new Error('StripeGateway needs a secretKey');
    this.secretKey = secretKey;
    this.webhookSecret = webhookSecret;
    this.fetchImpl = fetchImpl;
    this.apiBase = apiBase;
  }

  async #post(path, params, idempotencyKey) {
    let res;
    try {
      res = await this.fetchImpl(`${this.apiBase}${path}`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${this.secretKey}`,
          'Content-Type': 'application/x-www-form-urlencoded',
          ...(idempotencyKey ? { 'Idempotency-Key': idempotencyKey } : {}),
        },
        body: toFormBody(params),
        signal: AbortSignal.timeout(15000),
      });
    } catch (err) {
      throw new PaymentError('Could not reach the payment provider', { status: 502 });
    }
    let data = null;
    try {
      data = await res.json();
    } catch {
    }
    if (!res.ok) {
      throw new PaymentError(data?.error?.message || `Payment provider returned ${res.status}`);
    }
    return data;
  }

  async createCheckoutSession({
    orderId, title, description, unitAmountSen, quantity, methods,
    successUrl, cancelUrl, expiresAtUnix, customerEmail,
  }) {
    const params = {
      mode: 'payment',
      payment_method_types: methods,
      line_items: [
        {
          quantity,
          price_data: {
            currency: 'myr',
            unit_amount: unitAmountSen,
            product_data: { name: title, ...(description ? { description } : {}) },
          },
        },
      ],
      client_reference_id: orderId,
      metadata: { order_id: orderId },
      payment_intent_data: { metadata: { order_id: orderId } },
      success_url: successUrl,
      cancel_url: cancelUrl,
      expires_at: expiresAtUnix,
      ...(customerEmail ? { customer_email: customerEmail } : {}),
    };
    const session = await this.#post('/v1/checkout/sessions', params, `checkout-${orderId}`);
    if (!session?.id || !session?.url) throw new PaymentError('Payment provider returned an unexpected response');
    return { id: session.id, url: session.url };
  }

  async expireCheckoutSession(sessionId) {
    await this.#post(`/v1/checkout/sessions/${encodeURIComponent(sessionId)}/expire`, {});
  }

  async refund({ paymentIntentId, orderId }) {
    return this.#post(
      '/v1/refunds',
      { payment_intent: paymentIntentId, metadata: { order_id: orderId } },
      `refund-${orderId}`,
    );
  }

  verifyWebhook(rawBody, header, { now = Date.now(), toleranceSec = 300 } = {}) {
    if (!this.webhookSecret) throw new WebhookSignatureError('webhook secret is not configured');
    if (!header) throw new WebhookSignatureError('missing signature');

    const pairs = header.split(',').map((part) => part.trim().split('='));
    const timestamp = pairs.find(([k]) => k === 't')?.[1];
    const signatures = pairs.filter(([k]) => k === 'v1').map(([, v]) => v);
    if (!timestamp || !/^\d+$/.test(timestamp) || signatures.length === 0) {
      throw new WebhookSignatureError('malformed signature');
    }

    const expected = crypto.createHmac('sha256', this.webhookSecret).update(`${timestamp}.${rawBody}`).digest();
    const valid = signatures.some((sig) => {
      const given = Buffer.from(sig, 'hex');
      return given.length === expected.length && crypto.timingSafeEqual(given, expected);
    });
    if (!valid) throw new WebhookSignatureError('signature mismatch');

    if (Math.abs(now / 1000 - Number(timestamp)) > toleranceSec) {
      throw new WebhookSignatureError('timestamp outside tolerance');
    }
    try {
      return JSON.parse(rawBody);
    } catch {
      throw new WebhookSignatureError('body is not JSON');
    }
  }
}

function gatewayFromEnv(env = process.env) {
  if (!env.STRIPE_SECRET_KEY) return null;
  return new StripeGateway({
    secretKey: env.STRIPE_SECRET_KEY,
    webhookSecret: env.STRIPE_WEBHOOK_SECRET,
  });
}

module.exports = {
  SUPPORTED_METHODS,
  PaymentError,
  WebhookSignatureError,
  StripeGateway,
  gatewayFromEnv,
  signWebhookPayload,
  toFormBody,
};
