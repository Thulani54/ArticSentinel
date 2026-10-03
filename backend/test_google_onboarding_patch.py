"""Executes only google_auth with fully mocked network, database and responses."""
import ast
import logging
import os
import secrets
import sys
import unittest
from contextlib import nullcontext
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import MagicMock, patch

from google_onboarding_patch import patched_source

SOURCE = Path(sys.argv.pop(1)).read_text() if len(sys.argv) > 1 else ''


class GoogleOnboardingTests(unittest.TestCase):
    def setUp(self):
        self.source = patched_source(SOURCE)
        tree = ast.parse(self.source)
        node = next(node for node in tree.body
                    if isinstance(node, ast.FunctionDef) and node.name == 'google_auth')
        node.decorator_list = []
        node.body = [part for part in node.body if not isinstance(part, ast.ImportFrom)]
        module = ast.fix_missing_locations(ast.Module(body=[node], type_ignores=[]))
        self.user = SimpleNamespace(is_active=True)
        self.user_manager = MagicMock()
        self.user_manager.create_user.return_value = self.user
        self.companies = MagicMock()
        self.profiles = MagicMock()
        self.http = MagicMock()
        self.http.get.return_value = SimpleNamespace(status_code=200, json=lambda: {
            'aud': 'test-client', 'email_verified': True,
            'email': 'customer@example.com', 'given_name': 'Example', 'family_name': 'Customer'})
        self.namespace = {
            'os': os, 'secrets': secrets, 'http_requests': self.http,
            'logger': logging.getLogger(__name__),
            'User': SimpleNamespace(objects=self.user_manager),
            'Company': SimpleNamespace(objects=self.companies),
            'UserProfile': SimpleNamespace(objects=self.profiles),
            'transaction': SimpleNamespace(atomic=nullcontext),
            'status': SimpleNamespace(HTTP_400_BAD_REQUEST=400,
                                     HTTP_503_SERVICE_UNAVAILABLE=503,
                                     HTTP_502_BAD_GATEWAY=502,
                                     HTTP_401_UNAUTHORIZED=401,
                                     HTTP_403_FORBIDDEN=403),
            'Response': lambda data, status=200: SimpleNamespace(data=data, status_code=status),
            'build_login_success_response': lambda user: SimpleNamespace(
                data={'token': 'mock-token'}, status_code=200),
        }
        exec(compile(module, '<isolated-google-auth>', 'exec'), self.namespace)

    def invoke(self):
        with patch.dict(os.environ, {'GOOGLE_OAUTH_CLIENT_IDS': 'test-client'}):
            return self.namespace['google_auth'](SimpleNamespace(data={'id_token': 'mock-token'}))

    def test_existing_account_skips_first_signup_onboarding(self):
        self.user_manager.filter.return_value.first.return_value = self.user
        response = self.invoke()
        self.assertIs(response.data['is_new_account'], False)
        self.user_manager.create_user.assert_not_called()

    def test_new_account_enters_onboarding(self):
        self.user_manager.filter.return_value.first.return_value = None
        response = self.invoke()
        self.assertIs(response.data['is_new_account'], True)
        self.user_manager.create_user.assert_called_once()
        self.companies.create.assert_called_once()
        self.profiles.create.assert_called_once()

    def test_disabled_account_still_rejected(self):
        self.user.is_active = False
        self.user_manager.filter.return_value.first.return_value = self.user
        response = self.invoke()
        self.assertEqual(response.status_code, 403)
        self.assertNotIn('is_new_account', response.data)

    def test_rejected_google_token_never_creates_account(self):
        self.http.get.return_value.status_code = 401
        self.assertEqual(self.invoke().status_code, 401)
        self.user_manager.filter.assert_not_called()

    def test_patch_is_idempotent(self):
        self.assertEqual(patched_source(self.source), self.source)


if __name__ == '__main__':
    unittest.main()
