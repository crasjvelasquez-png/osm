# Project structure

The repository is grouped by the part of the app each directory owns. The files at the repository root are the project entry points and platform build configuration, so they need to stay there for Qt and platform tooling to find them.

## Source and resources

- `src/` — C++ application and measurement logic
- `qml/` — Qt Quick interface
- `shaders/` — graph and visualization shaders
- `audio/` — bundled noise and audio resources
- `fonts/` — bundled fonts
- `icons/` — application and platform icons
- `tests/` — automated tests and test projects

## Project and platform files

- `OpenSoundMeter.pro` — qmake project and build configuration
- `Info.plist`, `info.entitlements` — macOS bundle metadata and entitlements
- `images.qrc`, `qml.qrc` — Qt resource manifests
- `OpenSoundMeter.desktop`, `linuxdeployosm.sh` — Linux launcher and packaging helper
- `README.md` — project overview and starting point
- `PRODUCT.md` — product direction
- `CONTRIBUTING` — contribution guidance
- `LICENSE` — license terms

## Documentation site

- `docs/` contains the website sources and project references. Files such as `docs/_config.yml`, `docs/Gemfile`, and `docs/CNAME` configure the published docs site.

## Build output

Keep generated build files and app bundles outside this source repository. The current Apple Silicon build checkout is `../osm-build-apple-silicon/` when opened from the `Project Folders` directory.
