import React from 'react';

const sizeMap = {
  xs: { iconSize:60, radius:10, barWidth:8, barHeight:32, barTop:14, left:17, right:17, top:{left:22,width:29,height:7}, bottom:{left:28,top:29,width:29,height:7}, glow:{bottom:5,width:26,height:3,blur:'blur(2px)'}, shadow:'0 0 8px #a100ff', glowPurple:'0 0 6px #c300ff', glowBlue:'0 0 6px #00cfff', glowCyan:'0 0 4px #48dfff', glowViolet:'0 0 4px #8d2eff' },
  sm: { iconSize:80, radius:14, barWidth:11, barHeight:43, barTop:18, left:23, right:23, top:{left:29,width:38,height:9}, bottom:{left:38,top:38,width:38,height:9}, glow:{bottom:6,width:34,height:4,blur:'blur(3px)'}, shadow:'0 0 12px #a100ff', glowPurple:'0 0 8px #c300ff', glowBlue:'0 0 8px #00cfff', glowCyan:'0 0 6px #48dfff', glowViolet:'0 0 6px #8d2eff' },
  md: { iconSize:120, radius:18, barWidth:16, barHeight:64, barTop:28, left:35, right:35, top:{left:43,width:58,height:13}, bottom:{left:57,top:58,width:58,height:13}, glow:{bottom:10,width:50,height:6,blur:'blur(5px)'}, shadow:'0 0 16px #a100ff', glowPurple:'0 0 10px #c300ff', glowBlue:'0 0 10px #00cfff', glowCyan:'0 0 8px #48dfff', glowViolet:'0 0 8px #8d2eff' },
  lg: { iconSize:180, radius:26, barWidth:24, barHeight:96, barTop:42, left:52, right:52, top:{left:64,width:86,height:19}, bottom:{left:85,top:87,width:86,height:19}, glow:{bottom:14,width:76,height:8,blur:'blur(7px)'}, shadow:'0 0 24px #a100ff', glowPurple:'0 0 14px #c300ff', glowBlue:'0 0 14px #00cfff', glowCyan:'0 0 10px #48dfff', glowViolet:'0 0 10px #8d2eff' },
  xl: { iconSize:260, radius:36, barWidth:35, barHeight:140, barTop:60, left:75, right:75, top:{left:93,width:125,height:28}, bottom:{left:123,top:125,width:125,height:28}, glow:{bottom:20,width:110,height:12,blur:'blur(10px)'}, shadow:'0 0 32px #a100ff', glowPurple:'0 0 18px #c300ff', glowBlue:'0 0 18px #00cfff', glowCyan:'0 0 14px #48dfff', glowViolet:'0 0 14px #8d2eff' },
};

export const CSSLogo = ({ size='md', className='', onClick=null, animated=false, float=false }) => {
  const s = sizeMap[size] || sizeMap.md;
  const animStyle = animated ? { animation: 'nexusPulse 3s ease-in-out infinite' } : {};
  const floatStyle = float ? { animation: 'nexusFloat 4s ease-in-out infinite' } : {};
  const cursorStyle = onClick ? { cursor: 'pointer' } : {};

  return (
    <div style={{
      position:'relative', width:`${s.iconSize}px`, height:`${s.iconSize}px`,
      borderRadius:`${s.radius}px`, background:'#05050b', overflow:'hidden',
      boxShadow:s.shadow, flexShrink:0, display:'inline-block',
      ...animStyle, ...floatStyle, ...cursorStyle
    }} className={className} onClick={onClick}>
      <div className="csslogo-glow-bar" style={{
          position:'absolute', inset:0, borderRadius:`${s.radius}px`, padding:'2px',
          background:'linear-gradient(135deg, #ff38ff, #a100ff, #39d7ff)',
          WebkitMask:'linear-gradient(#000 0 0) content-box, linear-gradient(#000 0 0)',
          WebkitMaskComposite:'xor', maskComposite:'exclude',
          filter:'blur(0.5px)', pointerEvents:'none'
      }} />
      <div style={{
          position:'absolute', left:`${s.left}px`, top:`${s.barTop}px`,
          width:`${s.barWidth}px`, height:`${s.barHeight}px`,
          background:'linear-gradient(180deg, #ff8cff, #a100ff)',
          clipPath:'polygon(0 0, 100% 15%, 100% 85%, 0 100%)',
          boxShadow:s.glowPurple
      }} />
      <div style={{
          position:'absolute', right:`${s.right}px`, top:`${s.barTop}px`,
          width:`${s.barWidth}px`, height:`${s.barHeight}px`,
          background:'linear-gradient(180deg, #6cecff, #0077ff)',
          clipPath:'polygon(0 15%, 100% 0, 100% 100%, 0 85%)',
          boxShadow:s.glowBlue
      }} />
      <div style={{
          position:'absolute', left:`${s.top.left}px`, top:`${s.barTop}px`,
          width:`${s.top.width}px`, height:`${s.top.height}px`,
          background:'linear-gradient(90deg, #ffffff, #4ce3ff)',
          transform:'rotate(33deg)', transformOrigin:'left center',
          clipPath:'polygon(0 0, 100% 0, 85% 100%, 15% 100%)',
          boxShadow:s.glowCyan
      }} />
      <div style={{
          position:'absolute', left:`${s.bottom.left}px`, top:`${s.bottom.top}px`,
          width:`${s.bottom.width}px`, height:`${s.bottom.height}px`,
          background:'linear-gradient(90deg, #8000ff, #6b45ff)',
          transform:'rotate(36deg)', transformOrigin:'left center',
          clipPath:'polygon(15% 0, 85% 0, 100% 100%, 0 100%)',
          boxShadow:s.glowViolet
      }} />
      <div style={{
          position:'absolute', bottom:`${s.glow.bottom}px`, left:'50%',
          transform:'translateX(-50%)', width:`${s.glow.width}px`,
          height:`${s.glow.height}px`,
          background:'linear-gradient(90deg, #b100ff, #5275ff)',
          borderRadius:'50%', filter:s.glow.blur, opacity:0.9
      }} />
    </div>
  );
};

export default CSSLogo;
