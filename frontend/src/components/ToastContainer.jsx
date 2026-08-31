import React from 'react';
import { CheckCircle, AlertTriangle, Building2, X } from 'lucide-react';

export default function ToastContainer({ toasts, removeToast }) {
  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2 max-w-sm w-full pointer-events-none">
      {toasts.map(toast => {
        let styleClass = "bg-white border-green-300 text-green-900 shadow-lg";
        let icon = <CheckCircle size={18} className="text-green-600" />;

        if (toast.tipo === 'error') {
          styleClass = "bg-red-50 border-red-200 text-red-900 shadow-lg";
          icon = <AlertTriangle size={18} className="text-red-600" />;
        } else if (toast.tipo === 'info') {
          styleClass = "bg-blue-50 border-blue-200 text-blue-900 shadow-lg";
          icon = <Building2 size={18} className="text-blue-600" />;
        }

        return (
          <div 
            key={toast.id} 
            className={`pointer-events-auto border rounded-lg p-4 flex justify-between items-start gap-3 transition-all duration-300 shadow ${styleClass}`}
          >
            <div className="flex gap-2.5 items-start">
              {icon}
              <div className="text-xs font-semibold leading-normal">
                {toast.mensagem}
              </div>
            </div>
            <button 
              onClick={() => removeToast(toast.id)}
              className="text-slate-400 hover:text-slate-600 focus:outline-none shrink-0"
            >
              <X size={14} />
            </button>
          </div>
        );
      })}
    </div>
  );
}
