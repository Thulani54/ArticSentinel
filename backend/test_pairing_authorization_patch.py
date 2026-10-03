"""Isolated tests of the actual device handlers; no database or live requests.

python test_pairing_authorization_patch.py device/views.py device/gas_views.py
"""
import ast
import json
import logging
import sys
import unittest
from contextlib import nullcontext
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from django.conf import settings

if not settings.configured:
    settings.configure(SECRET_KEY='isolated-pairing-test', USE_TZ=True,
                       INSTALLED_APPS=['django.contrib.auth', 'django.contrib.contenttypes', 'rest_framework.authtoken'],
                       DATABASES={'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': ':memory:'}},
                       REST_FRAMEWORK={'DEFAULT_AUTHENTICATION_CLASSES': ['rest_framework.authentication.TokenAuthentication']})
    import django
    django.setup()

from django.core.exceptions import ValidationError
from django.http import JsonResponse
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.test import APIRequestFactory, force_authenticate

from pairing_authorization_patch import patched_source

SOURCE = Path(sys.argv.pop(1)).read_text()
GAS_SOURCE = Path(sys.argv.pop(1)).read_text()


class PairingAuthorizationTests(unittest.TestCase):
    def setUp(self):
        self.source = patched_source(SOURCE)
        nodes = {}
        for node in ast.parse(self.source).body:
            if isinstance(node, ast.FunctionDef) and node.name in ('list_devices', 'create_device'):
                node.body = self.remove_local_imports(node.body)
                nodes[node.name] = node
        helper = next(node for node in ast.parse(GAS_SOURCE).body
                      if isinstance(node, ast.FunctionDef) and node.name == '_user_can_access')
        module = ast.fix_missing_locations(ast.Module(body=[helper, *nodes.values()], type_ignores=[]))
        self.devices = MagicMock()
        self.units = MagicMock()
        self.lookup = MagicMock(return_value=SimpleNamespace(id=9))
        self.secondary = MagicMock()
        self.secondary.filter.return_value.exists.return_value = False
        self.user = SimpleNamespace(is_authenticated=True, is_active=True, is_superuser=False,
                                    profile=SimpleNamespace(business_id=9, secondary_businesses=self.secondary))
        self.namespace = {
            'api_view': api_view, 'permission_classes': permission_classes,
            'IsAuthenticated': IsAuthenticated, 'json': json, 'JsonResponse': JsonResponse,
            'get_object_or_404': self.lookup, 'Device': self.devices, 'Unit': self.units,
            'Company': object, 'transaction': SimpleNamespace(atomic=nullcontext),
            'serialize_device': lambda device, include_unit_details: {'id': 1, 'device_id': 'TEST'},
            'ValidationError': ValidationError, 'logger': logging.getLogger(__name__),
        }
        exec(compile(module, '<isolated-device-handlers>', 'exec'), self.namespace)
        self.factory = APIRequestFactory()

    @staticmethod
    def remove_local_imports(body):
        class RemoveHelperImport(ast.NodeTransformer):
            def visit_ImportFrom(self, node):
                return None if node.module == 'gas_views' else node
        transform = RemoveHelperImport()
        return [transform.visit(node) for node in body]

    def request(self, handler, authenticate=True, **data):
        body = {'business_id': 9, 'name': 'Test scale', 'device_id': 'TEST', 'device_type': 'gas_cylinder', **data}
        request = self.factory.post('/', body, format='json')
        if authenticate:
            force_authenticate(request, user=self.user)
        return self.namespace[handler](request)

    def test_anonymous_list_and_create_are_rejected_before_lookup(self):
        for handler in ('list_devices', 'create_device'):
            self.assertEqual(self.request(handler, authenticate=False).status_code, 401)
        self.lookup.assert_not_called()
        self.devices.assert_not_called()
        self.devices.objects.filter.assert_not_called()

    def test_cross_company_is_rejected_without_data_access_or_creation(self):
        self.user.profile.business_id = 99
        for handler in ('list_devices', 'create_device'):
            self.assertEqual(self.request(handler).status_code, 403)
        self.devices.assert_not_called()
        self.devices.objects.filter.assert_not_called()

    def test_primary_business_can_list_and_create(self):
        self.assertEqual(self.request('list_devices').status_code, 200)
        self.assertEqual(self.request('create_device').status_code, 201)
        self.devices.return_value.full_clean.assert_called_once()
        self.devices.return_value.save.assert_called_once()

    def test_secondary_business_can_list_and_create(self):
        self.user.profile.business_id = 99
        self.secondary.filter.return_value.exists.return_value = True
        self.assertEqual(self.request('list_devices').status_code, 200)
        self.assertEqual(self.request('create_device').status_code, 201)
        self.secondary.filter.assert_called_with(id=9)

    def test_superuser_access_is_preserved(self):
        self.user.is_superuser = True
        self.user.profile = None
        self.assertEqual(self.request('list_devices').status_code, 200)
        self.assertEqual(self.request('create_device').status_code, 201)

    def test_missing_profile_is_denied(self):
        self.user.profile = None
        for handler in ('list_devices', 'create_device'):
            self.assertEqual(self.request(handler).status_code, 403)

    def test_missing_business_is_still_validation_error(self):
        self.assertEqual(self.request('create_device', business_id=None).status_code, 400)
        self.devices.assert_not_called()

    def test_patch_is_idempotent(self):
        self.assertEqual(patched_source(self.source), self.source)


if __name__ == '__main__':
    unittest.main()
