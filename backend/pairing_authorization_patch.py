"""Protect only the effective list_devices/create_device server definitions.

Uses the project's existing Token/Bearer/session authentication and the same
primary/secondary business authorization helper as the gas endpoints.
"""
import ast
import sys
from datetime import datetime, timezone
from pathlib import Path


def patched_source(source):
    tree = ast.parse(source)
    targets = {}
    for node in tree.body:
        if isinstance(node, ast.FunctionDef) and node.name in ('list_devices', 'create_device'):
            targets[node.name] = node
    if set(targets) != {'list_devices', 'create_device'}:
        raise ValueError('Expected effective device list and create handlers.')
    lines = source.splitlines(keepends=True)
    for node in sorted(targets.values(), key=lambda item: item.lineno, reverse=True):
        start = min(part.lineno for part in node.decorator_list) - 1
        body = ''.join(lines[node.lineno - 1:node.end_lineno])
        marker = 'from .gas_views import _user_can_access'
        if marker in body:
            continue
        lookup = '        company = get_object_or_404(Company, id=business_id)\n'
        if body.count(lookup) != 1:
            raise ValueError(f'{node.name} company lookup changed; inspect before patching.')
        body = body.replace(lookup, lookup + '\n'
                            '        from .gas_views import _user_can_access\n'
                            '        if not _user_can_access(request.user, company):\n'
                            "            return JsonResponse({'error': 'Access denied to this business'}, status=403)\n")
        decorated = '@api_view(["POST"])\n@permission_classes([IsAuthenticated])\n' + body
        lines[start:node.end_lineno] = [decorated]
    updated = ''.join(lines)
    ast.parse(updated)
    return updated


if __name__ == '__main__':
    target = Path(sys.argv[1])
    original = target.read_text()
    updated = patched_source(original)
    if updated != original:
        stamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
        target.with_suffix(f'.py.before-pairing-auth-{stamp}').write_text(original)
        target.write_text(updated)
    print('Device list and create authorization is ready.')
