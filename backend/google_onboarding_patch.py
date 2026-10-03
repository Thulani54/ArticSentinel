"""Narrow, idempotent patch for the existing server Google sign-in handler.

Run with the path to user/team_views.py. A timestamped backup is written beside
the original. No account records or authentication logic are changed.
"""
import ast
import sys
from datetime import datetime, timezone
from pathlib import Path


def patched_source(source):
    tree = ast.parse(source)
    function = next(node for node in tree.body
                    if isinstance(node, ast.FunctionDef) and node.name == 'google_auth')
    lines = source.splitlines(keepends=True)
    body = ''.join(lines[function.lineno - 1:function.end_lineno])
    if "response.data['is_new_account'] = is_new_account" in body:
        return source
    lookup = '    if user is None:\n'
    result = '    return build_login_success_response(user)'
    if body.count(lookup) != 1 or body.count(result) != 1:
        raise ValueError('Google sign-in handler changed; inspect before patching.')
    body = body.replace(lookup, '    is_new_account = user is None\n' + lookup)
    body = body.replace(result, "    response = build_login_success_response(user)\n"
                        "    response.data['is_new_account'] = is_new_account\n"
                        "    return response")
    lines[function.lineno - 1:function.end_lineno] = [body]
    updated = ''.join(lines)
    ast.parse(updated)
    return updated


if __name__ == '__main__':
    target = Path(sys.argv[1])
    original = target.read_text()
    updated = patched_source(original)
    if updated != original:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        target.with_suffix(f'.py.before-onboarding-{stamp}').write_text(original)
        target.write_text(updated)
    print('Google signup onboarding response flag is ready.')
