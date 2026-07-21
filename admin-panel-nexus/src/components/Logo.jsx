import React from 'react';
import logo from '../../assets/icons/logo.svg';

/**
 * Componente Logo - Exibe o ícone Nexustwos
 * Ideal para header, navbar e seções de branding
 */
export const Logo = ({ 
  size = 'md', 
  className = '',
  onClick = null,
  as = 'img' 
}) => {
  const sizeClasses = {
    xs: 'w-8 h-8',
    sm: 'w-12 h-12',
    md: 'w-16 h-16',
    lg: 'w-24 h-24',
    xl: 'w-32 h-32',
  };

  if (as === 'img') {
    return (
      <img
        src={logo}
        alt="Nexustwos Logo"
        className={`${sizeClasses[size]} ${className} ${onClick ? 'cursor-pointer' : ''}`}
        onClick={onClick}
      />
    );
  }

  return (
    <svg
      viewBox="0 0 1024 1024"
      className={`${sizeClasses[size]} ${className} ${onClick ? 'cursor-pointer' : ''}`}
      onClick={onClick}
    >
      <image href={logo} x="0" y="0" width="1024" height="1024" />
    </svg>
  );
};

export default Logo;
