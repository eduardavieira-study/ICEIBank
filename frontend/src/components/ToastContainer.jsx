import React from 'react';
import { CheckCircle, AlertTriangle, Building2, X } from 'lucide-react';

export default function ToastContainer({ toasts, removeToast, isDark = true }) {
  return (
    <div className="fixed bottom-4 right-4 z-50 flex flex-col gap-2 max-w-sm w-full pointer-events-none">
      {toasts.map(toast => {
        let styleClass = isDark 
          ? "bg-green-950 border-green-900 text-green-100 shadow-lg" 
          : "bg-emerald-50 border-emerald-300 text-emerald-900 shadow-lg";
        let icon = <CheckCircle size={18} className={isDark ? "text-green-400" : "text-emerald-600"} />;

        if (toast.tipo === 'error') {
          styleClass = isDark 
            ? "bg-red-950 border-red-900 text-red-100 shadow-lg" 
            : "bg-red-50 border-red-200 text-red-900 shadow-lg";
          icon = <AlertTriangle size={18} className={isDark ? "text-red-400" : "text-red-600"} />;
        } else if (toast.tipo === 'info') {
          styleClass = isDark 
            ? "bg-blue-950 border-blue-800 text-blue-100 shadow-lg" 
            : "bg-blue-50 border-blue-200 text-blue-900 shadow-lg";
          icon = <Building2 size={18} className={isDark ? "text-blue-400" : "text-blue-600"} />;
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
              className={`${isDark ? 'text-gray-200 hover:text-gray-400' : 'text-slate-400 hover:text-slate-600'} focus:outline-none shrink-0`}
            >
              <X size={14} />
            </button>
          </div>
        );
      })}
    </div>
  );
}
