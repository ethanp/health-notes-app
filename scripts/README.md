# Health Notes - Deployment Scripts

This directory contains deployment scripts for the Health Notes Flutter app.

## Architecture

The deployment scripts use a shared base class architecture for better code organization and maintainability:

- **`deployment_base.py`** - Common base class with shared functionality
- **`deploy_to_iphone.py`** - iPhone-specific deployment implementation
- **`deploy_to_simulator.py`** - Simulator-specific deployment implementation

## Scripts

### 🚀 `deploy_to_iphone.py` (Recommended)
**Python-based iPhone deployment script with a simplified, reliable flow.**

**Features:**
- ✅ Detects a single connected iPhone and installs directly
- ✅ Falls back to Flutter’s interactive device selector when needed
- ✅ Clean, colored output (via shared base)
- ✅ **Intelligent build caching** – skips rebuilds when no changes detected
- ✅ Warns when a VPN is likely active (wireless deploy may fail)
- ✅ Ignores iOS simulators; use `deploy_to_simulator.py` instead
- 🚫 Requires exactly one physical iPhone connected; otherwise fails fast

**Usage:**
```bash
# From project root directory
python3 scripts/deploy_to_iphone.py
```

### 📱 `deploy_to_simulator.py`
**Python-based iOS Simulator deployment script for testing.**

**Features:**
- ✅ Automatically starts iOS Simulator
- ✅ Debug build for faster testing
- ✅ Clean, colored output
- ✅ **Intelligent build caching** - Skips rebuilds when no changes detected

**Usage:**
```bash
# From project root directory
python3 scripts/deploy_to_simulator.py
```

### 🔧 `deployment_base.py`
**Shared base class providing common functionality:**

- **Build Management**: Intelligent caching, dependency management, code generation
- **Output Formatting**: Colored terminal output with consistent styling
- **Command Execution**: Safe command running with error handling
- **File Monitoring**: Hash-based change detection for build optimization
- **Prerequisites Checking**: Flutter availability and project structure validation

## Intelligent Build Caching

The deployment scripts now include intelligent build caching to avoid unnecessary rebuilds and deployments:

### How It Works
- **File Monitoring**: Monitors changes in `lib/`, `assets/`, `ios/Runner/`, and key configuration files
- **Hash Comparison**: Uses MD5 hashes to detect changes in source files and assets
- **Smart Rebuilds**: Only rebuilds when actual changes are detected
- **Deployment Skipping**: Skips entire deployment if no changes since last successful deployment
- **Cache Files**: Stores build state and deployment timestamps in `.build_hash_iphone` and `.build_hash_simulator` (automatically ignored by git)

### Monitored Files/Directories
- `lib/` - All Dart source files
- `assets/` - Images, fonts, and other assets
- `ios/Runner/` - iOS-specific files
- `ios/Runner/Assets.xcassets/` - iOS app icons and images
- `pubspec.yaml` - Dependencies and configuration
- `pubspec.lock` - Locked dependency versions
- `ios/Runner/Info.plist` - iOS app configuration

### Benefits
- **Faster Deployments**: Skip clean/rebuild when no changes
- **Reduced Build Time**: Only rebuild when necessary
- **Skip Unnecessary Deployments**: Skip entire deployment process if no changes detected
- **Better Developer Experience**: Quick iterations during development
- **Timestamp Tracking**: Know when the last deployment occurred

### Cache File Format
The cache files now store both file hashes and deployment timestamps:
```json
{
  "hashes": {
    "lib": "bb06ea2f0d0fc96ff039b52d9da46f50",
    "assets": "57521b7e63235e0b585c9b206e9e76c4",
    "ios/Runner": "b7b9ae089f846bde0579da0477577967",
    "pubspec.yaml": "9c2b03c844eda336cffd93b2c842d5ed"
  },
  "last_deploy_time": "2025-08-25 14:32:38"
}
```

## Requirements

- Python 3.6+
- Flutter SDK
- Xcode (for iOS development)
- macOS (for iOS development)

## Troubleshooting

### VPN Issues
If you have a VPN running, it may interfere with wireless device connections.
- The script will issue a warning when a VPN is likely active
- Prefer USB connection for reliable installs
- If you prefer wireless, ensure both devices are on the same Wi‑Fi
- Consider disabling VPN or configuring split‑tunneling

### Device Trust Issues
If your iPhone is connected but not recognized:
1. Unlock your iPhone
2. Look for "Trust This Computer?" dialog
3. Tap "Trust" and enter your passcode
4. If no dialog appears, go to Settings > General > VPN & Device Management

### Developer Mode
Ensure Developer Mode is enabled on your iPhone:
1. Go to Settings > Privacy & Security > Developer Mode
2. Toggle Developer Mode ON
3. Restart your iPhone

### Build Cache Issues
If you encounter build cache issues:
1. Delete the cache files: `rm .build_hash_iphone .build_hash_simulator`
2. Run the deployment script again
3. The script will rebuild and create new cache files

## Code Organization

### Base Class (`DeploymentBase`)
```python
class DeploymentBase(ABC):
    def __init__(self, script_name: str, build_type: str = "release")
    def build_app(self) -> bool
    def check_prerequisites(self) -> bool
    @abstractmethod
    def deploy(self) -> bool
```

### iPhone Implementation (`IPhoneDeployment`)
```python
class IPhoneDeployment(DeploymentBase):
    def check_vpn(self) -> bool
    def parse_flutter_devices(self) -> Tuple[List[Dict], List[Dict]]
    def deploy(self) -> bool
```

### Simulator Implementation (`SimulatorDeployment`)
```python
class SimulatorDeployment(DeploymentBase):
    def start_simulator(self) -> bool
    def deploy(self) -> bool
```

## Usage Examples

```bash
# Deploy to connected iPhone (recommended)
python3 scripts/deploy_to_iphone.py

# Deploy to iOS Simulator for testing
python3 scripts/deploy_to_simulator.py

# Run from any directory (scripts will check for pubspec.yaml)
cd /path/to/health_notes
python3 scripts/deploy_to_iphone.py

# Using wrapper scripts
./deploy_to_iphone
./deploy_to_simulator
```
