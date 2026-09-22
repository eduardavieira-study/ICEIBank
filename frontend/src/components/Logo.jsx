import React from 'react';

export default function Logo({ inverted = false, className = '' }) {
  return (
    <span className={`font-display font-extrabold tracking-tight whitespace-nowrap ${inverted ? 'text-white' : ''} ${className}`}>
      ICEI<span className={inverted ? 'text-white/70' : 'text-primary-600 dark:text-primary-400'}>Bank</span>
    </span>
  );
}
