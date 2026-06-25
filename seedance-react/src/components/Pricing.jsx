import { Check, X } from 'lucide-react'

const PLANS = [
  {
    name: 'Free',
    price: '$0',
    period: '/mo',
    badge: 'Current Plan',
    features: [
      { ok: true,  text: '30 minutes of free usage' },
      { ok: true,  text: 'Unlimited generations per session' },
      { ok: true,  text: 'Up to 1080p quality' },
      { ok: true,  text: '5-second videos' },
      { ok: false, text: '4K quality (Pro only)' },
      { ok: false, text: 'Priority queue' },
      { ok: false, text: 'Long video (30 min)' },
    ],
    cta: 'Current Plan', pro: false,
  },
  {
    name: 'Pro',
    price: '$12',
    period: '/mo',
    badge: 'Most Popular',
    features: [
      { ok: true, text: 'Unlimited usage' },
      { ok: true, text: '4K Ultra HD quality' },
      { ok: true, text: 'Up to 30-minute long videos' },
      { ok: true, text: 'Priority generation queue' },
      { ok: true, text: 'API access (sk_live_...)' },
      { ok: true, text: 'Commercial license' },
      { ok: true, text: 'Dedicated support' },
    ],
    cta: 'Upgrade to Pro', pro: true,
  },
]

export default function Pricing() {
  return (
    <section id="pricing" className="relative z-10 py-20 px-6">
      <div className="max-w-3xl mx-auto">
        <div className="text-center mb-14">
          <h2 className="text-4xl font-black tracking-tight mb-3">Simple Pricing</h2>
          <p className="text-[#8b8fa8]">Start free. No card required.</p>
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-5">
          {PLANS.map(plan => <PricingCard key={plan.name} plan={plan} />)}
        </div>
      </div>
    </section>
  )
}

function PricingCard({ plan }) {
  return (
    <div className="panel relative" style={plan.pro ? {
      borderColor: 'rgba(124,58,237,0.4)',
      background: 'linear-gradient(180deg, rgba(124,58,237,0.06) 0%, #10121a 100%)',
      boxShadow: '0 0 40px rgba(124,58,237,0.12)',
    } : {}}>
      <div className="inline-flex px-2.5 py-1 rounded-md text-[11px] font-bold tracking-wide mb-4"
        style={plan.pro
          ? { background: 'rgba(124,58,237,0.15)', color: '#a78bfa', border: '1px solid rgba(124,58,237,0.3)' }
          : { background: '#161925', color: '#8b8fa8', border: '1px solid rgba(255,255,255,0.07)' }}>
        {plan.badge}
      </div>
      <h3 className="text-xl font-bold mb-2">{plan.name}</h3>
      <div className="flex items-baseline gap-1 mb-6">
        <span className="text-4xl font-black tracking-tight">{plan.price}</span>
        <span className="text-[#8b8fa8]">{plan.period}</span>
      </div>
      <ul className="space-y-2.5 mb-7">
        {plan.features.map((f, i) => (
          <li key={i} className="flex items-center gap-2.5 text-sm">
            {f.ok
              ? <Check size={15} className="text-emerald-400 flex-shrink-0" />
              : <X size={15} className="text-red-400/50 flex-shrink-0" />}
            <span className={f.ok ? 'text-[#c0c3d8]' : 'text-[#555872]'}>{f.text}</span>
          </li>
        ))}
      </ul>
      <button className={plan.pro ? 'btn-primary w-full py-3' : 'w-full py-3 rounded-xl text-sm font-semibold text-[#8b8fa8] transition-all'}
        style={!plan.pro ? { background: '#161925', border: '1px solid rgba(255,255,255,0.07)' } : {}}>
        {plan.cta}
      </button>
    </div>
  )
}
