import { useEffect } from 'react'
import clsx from 'clsx'

export default function ToastContainer({ toasts, remove }) {
  return (
    <div className="fixed bottom-6 right-6 z-50 flex flex-col gap-2.5 pointer-events-none">
      {toasts.map(t => <Toast key={t.id} toast={t} remove={remove} />)}
    </div>
  )
}

function Toast({ toast, remove }) {
  useEffect(() => {
    const id = setTimeout(() => remove(toast.id), 3500)
    return () => clearTimeout(id)
  }, [toast.id, remove])

  const colors = {
    success: 'bg-emerald-400',
    error: 'bg-red-400',
    info: 'bg-purple-400',
  }
  return (
    <div className="pointer-events-auto flex items-center gap-3 px-4 py-3 rounded-xl text-sm text-white max-w-xs animate-slide-up"
      style={{ background: '#161925', border: '1px solid rgba(255,255,255,0.1)', boxShadow: '0 8px 32px rgba(0,0,0,0.5)' }}>
      <span className={clsx('w-2 h-2 rounded-full flex-shrink-0', colors[toast.type] || colors.info)} />
      {toast.message}
    </div>
  )
}
