import { useEffect, useRef } from 'react';
import { createPortal } from 'react-dom';

// Native modal focus containment, Escape handling and focus restoration.
export default function Modal({ children, onClose, label }) {
  const ref = useRef(null);
  useEffect(() => {
    const element = ref.current;
    const previousOverflow = document.body.style.overflow;
    element.showModal();
    document.body.style.overflow = 'hidden';
    return () => { element.close(); document.body.style.overflow = previousOverflow; };
  }, []);
  return createPortal(<dialog ref={ref} className="modal-veil" aria-label={label} onCancel={event => { event.preventDefault(); onClose(); }} onMouseDown={event => { if (event.target === event.currentTarget) onClose(); }}>{children}</dialog>, document.body);
}
