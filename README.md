# artic_sentinel

A navario project.

## Luthando cloud development environment

The repository includes a reproducible Flutter development container for
GitHub Codespaces and editors that support the Dev Container specification.
It installs Flutter 3.27.1, the Dart and Flutter editor extensions, and the
dependencies required for web and Linux development. Project packages are
restored automatically when the container is created.

To use it in GitHub Codespaces, select **Code → Codespaces → Create codespace**.
In VS Code, install the **Dev Containers** extension, open this repository, and
run **Dev Containers: Reopen in Container** from the command palette.

Once setup completes, start the web application on the preconfigured forwarded
port with:

```sh
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
