import React from 'react';
import { CheckCircle, AlertTriangle, Building2, X } from 'lucide-react';

export default function ToastContainer({ toasts, removeToast }) {
  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2.5 max-w-sm w-full pointer-events-none">
      {toasts.map(toast => {
        let styleClass = "bg-green-950/95 border border-emerald-800/70 text-emerald-100 shadow-2xl shadow-emerald-950/30";
        let icon = <CheckCircle size={18} className="text-emerald-400 shrink-0 mt-0.5" />;

        if (toast.tipo === 'error') {
          styleClass = "bg-red-950/95 border border-rose-800/70 text-red-100 shadow-2xl shadow-rose-950/30";
          icon = <AlertTriangle size={18} className="text-rose-400 shrink-0 mt-0.5" />;
        } else if (toast.tipo === 'info') {
          styleClass = "bg-blue-950/95 border border-blue-800/70 text-blue-100 shadow-2xl shadow-blue-950/30";
          icon = <Building2 size={18} className="text-blue-400 shrink-0 mt-0.5" />;
        }

        return (
          <div 
            key={toast.id} 
            className={`pointer-events-auto rounded-lg p-3.5 flex justify-between items-start gap-3 transition-all duration-300 backdrop-blur-md ${styleClass}`}
          >
            <div className="flex gap-2.5 items-start">
              {icon}
              <div className="text-xs font-semibold leading-relaxed">
                {toast.mensagem}
              </div>
            </div>
            <button 
              onClick={() => removeToast(toast.id)}
              className="text-gray-400 hover:text-white focus:outline-none shrink-0 transition"
              aria-label="Fechar"
            >
              <X size={14} />
            </button>
          </div>
        );
      })}
    </div>
  );
}
