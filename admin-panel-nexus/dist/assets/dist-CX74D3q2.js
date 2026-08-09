import{a as t}from"./rolldown-runtime-DOG2APjf.js";import{Y as e}from"./index-DWRjAJ3H.js";var a,r,o,i=t(e(),1),s={data:""},n=t=>{if("object"==typeof window){let e=(t?t.querySelector("#_goober"):window._goober)||Object.assign(document.createElement("style"),{innerHTML:" ",id:"_goober"});return e.nonce=window.__nonce__,e.parentNode||(t||document.head).appendChild(e),e.firstChild}return t||s},l=/(?:([\u0080-\uFFFF\w-%@]+) *:? *([^{;]+?);|([^;}{]*?) *{)|(}\s*)/g,d=/\/\*[^]*?\*\/|  +/g,c=/\n+/g,p=(t,e)=>{let a="",r="",o="";for(let i in t){let s=t[i];"@"==i[0]?"i"==i[1]?a=i+" "+s+";":r+="f"==i[1]?p(s,i):i+"{"+p(s,"k"==i[1]?"":e)+"}":"object"==typeof s?r+=p(s,e?e.replace(/([^,])+/g,t=>i.replace(/([^,]*:\S+\([^)]*\))|([^,])+/g,e=>/&/.test(e)?e.replace(/&/g,t):t?t+" "+e:e)):i):null!=s&&(i="-"==i[1]?i:i.replace(/[A-Z]/g,"-$&").toLowerCase(),o+=p.p?p.p(i,s):i+":"+s+";")}return a+(e&&o?e+"{"+o+"}":o)+r},m={},u=t=>{if("object"==typeof t){let e="";for(let a in t)e+=a+u(t[a]);return e}return t},f=(t,e,a,r,o)=>{let i=u(t),s=m[i]||(m[i]=(t=>{let e=0,a=11;for(;e<t.length;)a=101*a+t.charCodeAt(e++)>>>0;return"go"+a})(i));if(!m[s]){let e=i!==t?t:(t=>{let e,a,r=[{}];for(;e=l.exec(t.replace(d,""));)e[4]?r.shift():e[3]?(a=e[3].replace(c," ").trim(),r.unshift(r[0][a]=r[0][a]||{})):r[0][e[1]]=e[2].replace(c," ").trim();return r[0]})(t);m[s]=p(o?{["@keyframes "+s]:e}:e,a?"":"."+s)}let n=a&&m.g;return a&&(m.g=m[s]),((t,e,a,r)=>{r?e.data=e.data.replace(r,t):-1===e.data.indexOf(t)&&(e.data=a?t+e.data:e.data+t)})(m[s],e,r,n),s};function g(t){let e=this||{},a=t.call?t(e.p):t;return f(a.unshift?a.raw?((t,e,a)=>t.reduce((t,r,o)=>{let i=e[o];if(i&&i.call){let t=i(a),e=t&&t.props&&t.props.className||/^go/.test(t)&&t;i=e?"."+e:t&&"object"==typeof t?t.props?"":p(t,""):!1===t?"":t}return t+r+(null==i?"":i)},""))(a,[].slice.call(arguments,1),e.p):a.reduce((t,a)=>Object.assign(t,a&&a.call?a(e.p):a),{}):a,n(e.target),e.g,e.o,e.k)}g.bind({g:1});var y=g.bind({k:1});function b(t,e){let i=this||{};return function(){let s=arguments;function n(l,d){let c=Object.assign({},l),p=c.className||n.className;i.p=Object.assign({theme:r&&r()},c),i.o=/go\d/.test(p),c.className=g.apply(i,s)+(p?" "+p:""),e&&(c.ref=d);let m=t;return t[0]&&(m=c.as||t,delete c.as),o&&m[0]&&o(c),a(m,c)}return e?e(n):n}}var h=(t,e)=>(t=>"function"==typeof t)(t)?t(e):t,x=(()=>{let t=0;return()=>(++t).toString()})(),v=(()=>{let t;return()=>{if(void 0===t&&typeof window<"u"){let e=matchMedia("(prefers-reduced-motion: reduce)");t=!e||e.matches}return t}})(),w="default",$=(t,e)=>{let{toastLimit:a}=t.settings;switch(e.type){case 0:return{...t,toasts:[e.toast,...t.toasts].slice(0,a)};case 1:return{...t,toasts:t.toasts.map(t=>t.id===e.toast.id?{...t,...e.toast}:t)};case 2:let{toast:r}=e;return $(t,{type:t.toasts.find(t=>t.id===r.id)?1:0,toast:r});case 3:let{toastId:o}=e;return{...t,toasts:t.toasts.map(t=>t.id===o||void 0===o?{...t,dismissed:!0,visible:!1}:t)};case 4:return void 0===e.toastId?{...t,toasts:[]}:{...t,toasts:t.toasts.filter(t=>t.id!==e.toastId)};case 5:return{...t,pausedAt:e.time};case 6:let i=e.time-(t.pausedAt||0);return{...t,pausedAt:void 0,toasts:t.toasts.map(t=>({...t,pauseDuration:t.pauseDuration+i}))}}},j=[],E={toasts:[],pausedAt:void 0,settings:{toastLimit:20}},k={},A=(t,e=w)=>{k[e]=$(k[e]||E,t),j.forEach(([t,a])=>{t===e&&a(k[e])})},z=t=>Object.keys(k).forEach(e=>A(t,e)),N=(t=w)=>e=>{A(e,t)},O=t=>(e,a)=>{let r=((t,e="blank",a)=>({createdAt:Date.now(),visible:!0,dismissed:!1,type:e,ariaProps:{role:"status","aria-live":"polite"},message:t,pauseDuration:0,...a,id:(null==a?void 0:a.id)||x()}))(e,t,a);return N(r.toasterId||(t=>Object.keys(k).find(e=>k[e].toasts.some(e=>e.id===t)))(r.id))({type:2,toast:r}),r.id},_=(t,e)=>O("blank")(t,e);_.error=O("error"),_.success=O("success"),_.loading=O("loading"),_.custom=O("custom"),_.dismiss=(t,e)=>{let a={type:3,toastId:t};e?N(e)(a):z(a)},_.dismissAll=t=>_.dismiss(void 0,t),_.remove=(t,e)=>{let a={type:4,toastId:t};e?N(e)(a):z(a)},_.removeAll=t=>_.remove(void 0,t),_.promise=(t,e,a)=>{let r=_.loading(e.loading,{...a,...null==a?void 0:a.loading});return"function"==typeof t&&(t=t()),t.then(t=>{let o=e.success?h(e.success,t):void 0;return o?_.success(o,{id:r,...a,...null==a?void 0:a.success}):_.dismiss(r),t}).catch(t=>{let o=e.error?h(e.error,t):void 0;o?_.error(o,{id:r,...a,...null==a?void 0:a.error}):_.dismiss(r)}),t};var I=y`
from {
  transform: scale(0) rotate(45deg);
	opacity: 0;
}
to {
 transform: scale(1) rotate(45deg);
  opacity: 1;
}`,F=y`
from {
  transform: scale(0);
  opacity: 0;
}
to {
  transform: scale(1);
  opacity: 1;
}`,C=y`
from {
  transform: scale(0) rotate(90deg);
	opacity: 0;
}
to {
  transform: scale(1) rotate(90deg);
	opacity: 1;
}`,D=b("div")`
  width: 20px;
  opacity: 0;
  height: 20px;
  border-radius: 10px;
  background: ${t=>t.primary||"#ff4b4b"};
  position: relative;
  transform: rotate(45deg);

  animation: ${I} 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275)
    forwards;
  animation-delay: 100ms;

  &:after,
  &:before {
    content: '';
    animation: ${F} 0.15s ease-out forwards;
    animation-delay: 150ms;
    position: absolute;
    border-radius: 3px;
    opacity: 0;
    background: ${t=>t.secondary||"#fff"};
    bottom: 9px;
    left: 4px;
    height: 2px;
    width: 12px;
  }

  &:before {
    animation: ${C} 0.15s ease-out forwards;
    animation-delay: 180ms;
    transform: rotate(90deg);
  }
`,L=y`
  from {
    transform: rotate(0deg);
  }
  to {
    transform: rotate(360deg);
  }
`,S=b("div")`
  width: 12px;
  height: 12px;
  box-sizing: border-box;
  border: 2px solid;
  border-radius: 100%;
  border-color: ${t=>t.secondary||"#e0e0e0"};
  border-right-color: ${t=>t.primary||"#616161"};
  animation: ${L} 1s linear infinite;
`,M=y`
from {
  transform: scale(0) rotate(45deg);
	opacity: 0;
}
to {
  transform: scale(1) rotate(45deg);
	opacity: 1;
}`,P=y`
0% {
	height: 0;
	width: 0;
	opacity: 0;
}
40% {
  height: 0;
	width: 6px;
	opacity: 1;
}
100% {
  opacity: 1;
  height: 10px;
}`,T=b("div")`
  width: 20px;
  opacity: 0;
  height: 20px;
  border-radius: 10px;
  background: ${t=>t.primary||"#61d345"};
  position: relative;
  transform: rotate(45deg);

  animation: ${M} 0.3s cubic-bezier(0.175, 0.885, 0.32, 1.275)
    forwards;
  animation-delay: 100ms;
  &:after {
    content: '';
    box-sizing: border-box;
    animation: ${P} 0.2s ease-out forwards;
    opacity: 0;
    animation-delay: 200ms;
    position: absolute;
    border-right: 2px solid;
    border-bottom: 2px solid;
    border-color: ${t=>t.secondary||"#fff"};
    bottom: 6px;
    left: 6px;
    height: 10px;
    width: 6px;
  }
`,q=b("div")`
  position: absolute;
`,H=b("div")`
  position: relative;
  display: flex;
  justify-content: center;
  align-items: center;
  min-width: 20px;
  min-height: 20px;
`,Y=y`
from {
  transform: scale(0.6);
  opacity: 0.4;
}
to {
  transform: scale(1);
  opacity: 1;
}`,Z=b("div")`
  position: relative;
  transform: scale(0.6);
  opacity: 0.4;
  min-width: 20px;
  animation: ${Y} 0.3s 0.12s cubic-bezier(0.175, 0.885, 0.32, 1.275)
    forwards;
`,B=({toast:t})=>{let{icon:e,type:a,iconTheme:r}=t;return void 0!==e?"string"==typeof e?i.createElement(Z,null,e):e:"blank"===a?null:i.createElement(H,null,i.createElement(S,{...r}),"loading"!==a&&i.createElement(q,null,"error"===a?i.createElement(D,{...r}):i.createElement(T,{...r})))},G=t=>`\n0% {transform: translate3d(0,${-200*t}%,0) scale(.6); opacity:.5;}\n100% {transform: translate3d(0,0,0) scale(1); opacity:1;}\n`,J=t=>`\n0% {transform: translate3d(0,0,-1px) scale(1); opacity:1;}\n100% {transform: translate3d(0,${-150*t}%,-1px) scale(.6); opacity:0;}\n`,K=b("div")`
  display: flex;
  align-items: center;
  background: #fff;
  color: #363636;
  line-height: 1.3;
  will-change: transform;
  box-shadow: 0 3px 10px rgba(0, 0, 0, 0.1), 0 3px 3px rgba(0, 0, 0, 0.05);
  max-width: 350px;
  pointer-events: auto;
  padding: 8px 10px;
  border-radius: 8px;
`,Q=b("div")`
  display: flex;
  justify-content: center;
  margin: 4px 10px;
  color: inherit;
  flex: 1 1 auto;
  white-space: pre-line;
`;i.memo(({toast:t,position:e,style:a,children:r})=>{let o=t.height?((t,e)=>{let a=t.includes("top")?1:-1,[r,o]=v()?["0%{opacity:0;} 100%{opacity:1;}","0%{opacity:1;} 100%{opacity:0;}"]:[G(a),J(a)];return{animation:e?`${y(r)} 0.35s cubic-bezier(.21,1.02,.73,1) forwards`:`${y(o)} 0.4s forwards cubic-bezier(.06,.71,.55,1)`}})(t.position||e||"top-center",t.visible):{opacity:0},s=i.createElement(B,{toast:t}),n=i.createElement(Q,{...t.ariaProps},h(t.message,t));return i.createElement(K,{className:t.className,style:{...o,...a,...t.style}},"function"==typeof r?r({icon:s,message:n}):i.createElement(i.Fragment,null,s,n))});!function(t,e,i,s){p.p=e,a=t,r=i,o=s}(i.createElement);g`
  z-index: 9999;
  > * {
    pointer-events: auto;
  }
`;var R=_;export{R as t};
//# sourceMappingURL=dist-CX74D3q2.js.map