import React from 'react';
import { CheckCircle, AlertTriangle, Building2, X } from 'lucide-react';
import { useApp } from '../context/AppContext';

export default function ToastContainer() {
  const { toasts, removeToast } = useApp();

  return (
    <div className="fixed bottom-20 md:bottom-4 right-4 left-4 sm:left-auto z-50 flex flex-col gap-2 sm:max-w-sm w-auto pointer-events-none">
      {toasts.map((toast) => {
        let styleClass = 'bg-accent-500/10 border-accent-500/30 text-accent-700 dark:text-accent-300';
        let icon = <CheckCircle size={18} className="text-accent-500 shrink-0" />;

        if (toast.tipo === 'error') {
          styleClass = 'bg-red-500/10 border-red-500/30 text-red-600 dark:text-red-300';
          icon = <AlertTriangle size={18} className="text-red-500 shrink-0" />;
        } else if (toast.tipo === 'info') {
          styleClass = 'bg-primary-500/10 border-primary-500/30 text-primary-700 dark:text-primary-300';
          icon = <Building2 size={18} className="text-primary-500 shrink-0" />;
        }

        return (
          <div
            key={toast.id}
            className={`pointer-events-auto border rounded-md p-4 flex justify-between items-start gap-3 shadow-lg surface ${styleClass}`}
          >
            <div className="flex gap-2.5 items-start">
              {icon}
              <div className="text-xs font-semibold leading-normal">{toast.mensagem}</div>
            </div>
            <button onClick={() => removeToast(toast.id)} className="text-muted hover:text-inherit shrink-0">
              <X size={14} />
            </button>
          </div>
        );
      })}
    </div>
  );
}
