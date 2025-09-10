# Wireless iPhone Deployment Guide

## Problem
The deployment script is failing to connect to your wirelessly connected iPhone with the error:
```
Error: Browsing on the local area network for iPhone (8). Ensure the device is unlocked and attached with a cable or associated with the same local area network as this Mac.
The device must be opted into Developer Mode to connect wirelessly. (code -27)
```

## VPN Interference (Common Cause)
If you have a VPN running on your Mac, it can block local network discovery needed for wireless iPhone deployment. VPNs route all traffic through their servers, preventing your Mac from finding devices on your local network.

### VPN Solutions:
1. **🔌 Temporarily disable VPN** during deployment
2. **🔗 Use USB cable connection** (bypasses VPN entirely)
3. **🌐 Configure VPN split tunneling** to exclude local network traffic
4. **📱 Use iOS Simulator** for testing

## Solution Steps

### 1. Enable Developer Mode on iPhone
1. On your iPhone, go to **Settings > Privacy & Security > Developer Mode**
2. Toggle **Developer Mode** to ON
3. Your iPhone will restart
4. After restart, unlock your iPhone and confirm you want to enable Developer Mode

### 2. Trust Your Mac
1. Connect your iPhone to your Mac with a USB cable
2. On your iPhone, you should see a "Trust This Computer?" dialog
3. Tap **Trust** and enter your iPhone passcode
4. Go to **Settings > General > VPN & Device Management**
5. Tap on your Apple ID/Developer account
6. Tap **Trust** if prompted

### 3. Ensure Same Network
1. Make sure both your Mac and iPhone are connected to the same WiFi network
2. Check that your iPhone is unlocked and not in sleep mode

### 4. Alternative: Use USB Connection
If wireless deployment continues to fail, you can:
1. Connect your iPhone to your Mac with a USB cable
2. Run the deployment script again
3. The script will automatically detect the USB connection

### 5. Use iOS Simulator (For Testing)
If you just want to test the app quickly:
```bash
./deploy_to_simulator.sh
```

## VPN-Specific Troubleshooting

### Check if VPN is Active
```bash
ifconfig | grep utun
```

### Disable VPN Temporarily
- Use your VPN client's disconnect option
- Or disable it in System Preferences > Network

### Configure Split Tunneling (If Supported)
Many VPN clients support "split tunneling" which allows local network traffic to bypass the VPN:
1. Open your VPN client settings
2. Look for "Split Tunneling" or "Local Network Access"
3. Enable it and add your local network (usually 192.168.x.x or 10.x.x.x)

### USB Connection (Recommended with VPN)
USB connections bypass network issues entirely:
```bash
# Connect iPhone via USB, then run:
./deploy_to_iphone.sh
```

## Troubleshooting Commands

### Check Device Status
```bash
flutter devices
```

### Check Flutter Doctor
```bash
flutter doctor
```

### Manual Installation via Xcode
1. Open the project in Xcode: `open ios/Runner.xcworkspace`
2. Select your iPhone as the target device
3. Click the Run button (▶️)

## Common Issues

### "Device not found" Error
- Ensure your iPhone is unlocked
- Check that both devices are on the same WiFi network
- Try connecting via USB cable first
- **If using VPN: Disable VPN temporarily**

### "Developer Mode not enabled" Error
- Follow the Developer Mode steps above
- Restart your iPhone after enabling Developer Mode

### "Trust this computer" not appearing
- Try a different USB cable
- Restart both your Mac and iPhone
- Check that your iPhone is unlocked when connecting

### VPN Blocking Connection
- Disable VPN temporarily
- Use USB connection instead
- Configure VPN split tunneling
- Use iOS Simulator for testing

## Quick Fix Script
The updated `deploy_to_iphone.sh` script now:
- Detects VPN automatically and warns about interference
- Provides VPN-specific solutions
- Offers multiple deployment options (wireless, USB, simulator)
- Detects wireless connection issues automatically
- Provides step-by-step instructions
- Offers to continue with the build process even if connection fails
- Provides better error handling and troubleshooting tips
