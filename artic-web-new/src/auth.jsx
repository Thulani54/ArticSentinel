import { createContext, useContext, useMemo, useState } from 'react';
import { api } from './api';

const STORAGE_KEY = 'artic_auth';
const AuthContext = createContext(null);

function readStored() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }) {
  const [auth, setAuth] = useState(readStored);

  const value = useMemo(
    () => ({
      auth,
      token: auth?.token ?? null,
      business: auth?.business ?? null,
      user: auth?.user ?? null,
      async login(email, password) {
        const data = await api.login(email, password);
        const next = { token: data.token, user: data.user, business: data.business };
        setAuth(next);
        try {
          localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
        } catch {
          /* private mode — session-only auth still works */
        }
        return next;
      },
      logout() {
        setAuth(null);
        try {
          localStorage.removeItem(STORAGE_KEY);
        } catch {
          /* ignore */
        }
      },
    }),
    [auth],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth() {
  return useContext(AuthContext);
}
