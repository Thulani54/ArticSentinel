import { useCallback, useEffect, useState } from "react";
export function useOperation(load, dependencies) {
  const [state, setState] = useState({ data: null, loading: true, error: "" });
  const [revision, setRevision] = useState(0);
  const refresh = useCallback(() => setRevision((n) => n + 1), []);
  useEffect(() => {
    let current = true;
    setState({ data: null, loading: true, error: "" });
    Promise.resolve()
      .then(load)
      .then((data) => {
        if (current) setState({ data, loading: false, error: "" });
      })
      .catch((e) => {
        if (current) setState({ data: null, loading: false, error: e.message });
      });
    return () => {
      current = false;
    };
  }, [...dependencies, revision]);
  return { ...state, refresh };
}
