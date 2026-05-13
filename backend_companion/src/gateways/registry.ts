import { FawryAdapter } from './fawry.js';
import { PaymobAdapter } from './paymob.js';
import { PayPalAdapter } from './paypal.js';
import { PayTabsAdapter } from './paytabs.js';
import { SquareAdapter } from './square.js';
import { StripeAdapter } from './stripe.js';
import type { GatewayAdapter } from './types.js';

const adapters = new Map<string, GatewayAdapter>([
  ['stripe', new StripeAdapter()],
  ['paymob', new PaymobAdapter()],
  ['paytabs', new PayTabsAdapter()],
  ['fawry', new FawryAdapter()],
  ['paypal', new PayPalAdapter()],
  ['square', new SquareAdapter()],
]);

export function getGateway(id: string): GatewayAdapter | undefined {
  return adapters.get(id);
}

export function getAvailableGateways(): GatewayAdapter[] {
  return Array.from(adapters.values()).filter((a) => a.isAvailable());
}
