#!/bin/bash

# Health Notes - iPhone Deployment Script
# This script builds and installs the latest version of the app to your connected iPhone

set -e  # Exit on any error

echo "🚀 Health Notes - iPhone Deployment Script"
echo "=========================================="

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ Error: Flutter is not installed or not in PATH"
    exit 1
fi

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: pubspec.yaml not found. Please run this script from the project root directory."
    exit 1
fi

# Check for VPN
check_vpn() {
    local vpn_active=false
    
    # Check for common VPN interfaces
    if ifconfig | grep -q "utun[0-9]*"; then
        vpn_active=true
    fi
    
    # Check for VPN processes
    if pgrep -f "openvpn\|vpn\|tunnel" > /dev/null; then
        vpn_active=true
    fi
    
    # Check for VPN-related network services
    if networksetup -listallnetworkservices 2>/dev/null | grep -q "VPN"; then
        vpn_active=true
    fi
    
    echo "$vpn_active"
}

# Check for USB-connected iPhone
check_usb_iphone() {
    local usb_iphone=false
    local usb_device_id=""
    
    # Get the device ID of the USB-connected iPhone
    usb_device_id=$(flutter devices 2>/dev/null | grep "mobile.*ios" | grep -v "wireless" | awk '{print $2}' | head -1)
    
    if [ -n "$usb_device_id" ]; then
        usb_iphone=true
        echo "$usb_device_id"
    else
        echo "false"
    fi
}

# Check if iPhone is physically connected but not trusted
check_iphone_connection_status() {
    local status="unknown"
    
    # Check if iPhone is physically connected
    if system_profiler SPUSBDataType 2>/dev/null | grep -q "iPhone"; then
        # Check if Flutter can see it as a USB device
        if flutter devices 2>/dev/null | grep -q "mobile.*ios" | grep -v "wireless"; then
            status="usb_connected"
        else
            status="usb_connected_not_trusted"
        fi
    else
        status="not_connected"
    fi
    
    echo "$status"
}

echo "📱 Checking for connected devices..."
echo ""

# Get device list and check for issues
DEVICE_OUTPUT=$(flutter devices 2>&1)
echo "$DEVICE_OUTPUT"

# Check for USB iPhone first
USB_DEVICE_ID=$(check_usb_iphone)
IPHONE_STATUS=$(check_iphone_connection_status)
VPN_ACTIVE=$(check_vpn)

# Handle iPhone connection status
if [ "$IPHONE_STATUS" = "usb_connected_not_trusted" ]; then
    echo ""
    echo "📱 iPhone Connected but Not Trusted"
    echo "==================================="
    echo ""
    echo "Your iPhone is connected via USB, but Flutter cannot access it."
    echo "This usually means the iPhone needs to be trusted."
    echo ""
    echo "Please:"
    echo "1. Unlock your iPhone"
    echo "2. Look for a 'Trust This Computer?' dialog on your iPhone"
    echo "3. Tap 'Trust' and enter your iPhone passcode"
    echo "4. If no dialog appears, go to Settings > General > VPN & Device Management"
    echo "   and tap 'Trust' next to your Mac"
    echo ""
    echo "Press Enter when you've trusted your Mac..."
    read -r
    echo ""
    echo "Rechecking device connection..."
    DEVICE_OUTPUT=$(flutter devices 2>&1)
    echo "$DEVICE_OUTPUT"
    USB_DEVICE_ID=$(check_usb_iphone)
    IPHONE_STATUS=$(check_iphone_connection_status)
fi

# Only show VPN warning if there's no USB iPhone and there are wireless connection issues
if [ "$VPN_ACTIVE" = "true" ] && [ "$USB_DEVICE_ID" = "false" ]; then
    if echo "$DEVICE_OUTPUT" | grep -q "Error: Browsing on the local area network"; then
        echo ""
        echo "⚠️  VPN Detected - This may interfere with wireless device connections"
        echo "================================================================"
        echo ""
        echo "VPNs can block local network discovery needed for wireless iPhone deployment."
        echo "However, USB connections work fine with VPN."
        echo ""
        echo "Solutions:"
        echo "1. 🔌 Disconnect VPN temporarily and try again"
        echo "2. 🔗 Connect iPhone via USB cable (recommended with VPN)"
        echo "3. 🌐 Add your local network to VPN split tunneling (if supported)"
        echo "4. 📱 Use iOS Simulator instead"
        echo ""
        echo "Would you like to:"
        echo "a) Continue with wireless deployment (may fail)"
        echo "b) Build for USB deployment (connect iPhone via cable)"
        echo "c) Deploy to iOS Simulator instead"
        echo "d) Exit and fix VPN settings"
        echo ""
        read -p "Choose option (a/b/c/d): " choice
        
        case $choice in
            a)
                echo "Continuing with wireless deployment..."
                ;;
            b)
                echo "Building for USB deployment..."
                echo "Please connect your iPhone via USB cable before continuing."
                echo "Press Enter when ready..."
                read -r
                ;;
            c)
                echo "Switching to iOS Simulator deployment..."
                exec ./deploy_to_simulator.sh
                ;;
            d)
                echo "Exiting. Please disable VPN or configure split tunneling and try again."
                exit 1
                ;;
            *)
                echo "Invalid choice. Exiting."
                exit 1
                ;;
        esac
    fi
fi

# Check if there are wireless connection issues (only if no USB iPhone)
if [ "$USB_DEVICE_ID" = "false" ] && echo "$DEVICE_OUTPUT" | grep -q "Error: Browsing on the local area network"; then
    echo ""
    echo "⚠️  Wireless iPhone Connection Issue Detected"
    echo "=============================================="
    
    if [ "$VPN_ACTIVE" = "true" ]; then
        echo "This is likely caused by your VPN blocking local network discovery."
        echo ""
        echo "Quick fixes:"
        echo "1. 🔌 Temporarily disable VPN"
        echo "2. 🔗 Connect iPhone via USB cable"
        echo "3. 🌐 Configure VPN split tunneling to exclude local network"
        echo ""
    else
        echo "To fix this issue, please follow these steps:"
        echo ""
        echo "1. 📱 On your iPhone:"
        echo "   - Go to Settings > General > VPN & Device Management"
        echo "   - Tap on your Apple ID/Developer account"
        echo "   - Tap 'Trust' if prompted"
        echo "   - Go to Settings > Privacy & Security > Developer Mode"
        echo "   - Enable Developer Mode and restart your iPhone"
        echo ""
        echo "2. 🔗 Connect your iPhone to your Mac with a USB cable"
        echo "   - This will establish a more reliable connection"
        echo "   - Once connected via cable, wireless deployment should work"
        echo ""
        echo "3. 🌐 Ensure both devices are on the same WiFi network"
        echo ""
    fi
    
    echo "4. 🔄 Try running this script again after completing the steps above"
    echo ""
    echo "Would you like to continue with the build process anyway? (y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        echo "Build cancelled. Please fix the connection issue and try again."
        exit 1
    fi
fi

echo ""
echo "🧹 Cleaning previous build..."
flutter clean

echo ""
echo "📦 Getting dependencies..."
flutter pub get

echo ""
echo "🔨 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

echo ""
echo "🏗️  Building iOS release version..."
flutter build ios --release

echo ""
echo "📱 Installing to iPhone..."

# Check for USB iPhone again before installation
USB_DEVICE_ID_AFTER=$(check_usb_iphone)
IPHONE_STATUS_AFTER=$(check_iphone_connection_status)

if [ "$USB_DEVICE_ID_AFTER" != "false" ]; then
    echo "USB iPhone detected (ID: $USB_DEVICE_ID_AFTER) - proceeding with installation..."
    echo "Installing to USB-connected iPhone..."
    
    # Try to install with specific device ID
    if flutter install --release -d "$USB_DEVICE_ID_AFTER"; then
        echo ""
        echo "✅ Deployment complete! 🎉"
        echo ""
        echo "Your Health Notes app has been updated on your iPhone."
        echo "You can now disconnect your phone and use the app anywhere."
    else
        echo ""
        echo "❌ Installation failed!"
        echo ""
        echo "Troubleshooting tips:"
        echo "1. Make sure your iPhone is unlocked"
        echo "2. Check that you've trusted your Mac on your iPhone"
        echo "3. Ensure Developer Mode is enabled on your iPhone"
        if [ "$VPN_ACTIVE" = "true" ]; then
            echo "4. 🔌 Try disabling VPN temporarily"
            echo "5. 🌐 Configure VPN split tunneling to exclude local network"
        fi
        echo ""
        echo "The app has been built successfully. You can manually install it from Xcode."
        exit 1
    fi
elif [ "$IPHONE_STATUS_AFTER" = "usb_connected_not_trusted" ]; then
    echo "⚠️  iPhone connected but not trusted. Installation may fail."
    echo "Please ensure your iPhone is unlocked and trusted."
    echo "Press Enter to continue anyway..."
    read -r
    echo "Please select your iPhone when prompted:"
    
    # Try to install with better error handling
    if flutter install --release; then
        echo ""
        echo "✅ Deployment complete! 🎉"
        echo ""
        echo "Your Health Notes app has been updated on your iPhone."
        echo "You can now disconnect your phone and use the app anywhere."
    else
        echo ""
        echo "❌ Installation failed!"
        echo ""
        echo "Troubleshooting tips:"
        echo "1. Make sure your iPhone is unlocked"
        echo "2. Check that you've trusted your Mac on your iPhone"
        echo "3. Try connecting your iPhone via USB cable"
        echo "4. Ensure Developer Mode is enabled on your iPhone"
        echo "5. Check that both devices are on the same WiFi network"
        if [ "$VPN_ACTIVE" = "true" ]; then
            echo "6. 🔌 Try disabling VPN temporarily"
            echo "7. 🌐 Configure VPN split tunneling to exclude local network"
        fi
        echo ""
        echo "The app has been built successfully. You can manually install it from Xcode."
        exit 1
    fi
else
    echo "Please select your iPhone when prompted:"
    
    # Try to install with better error handling
    if flutter install --release; then
        echo ""
        echo "✅ Deployment complete! 🎉"
        echo ""
        echo "Your Health Notes app has been updated on your iPhone."
        echo "You can now disconnect your phone and use the app anywhere."
    else
        echo ""
        echo "❌ Installation failed!"
        echo ""
        echo "Troubleshooting tips:"
        echo "1. Make sure your iPhone is unlocked"
        echo "2. Check that you've trusted your Mac on your iPhone"
        echo "3. Try connecting your iPhone via USB cable"
        echo "4. Ensure Developer Mode is enabled on your iPhone"
        echo "5. Check that both devices are on the same WiFi network"
        if [ "$VPN_ACTIVE" = "true" ] && [ "$USB_DEVICE_ID_AFTER" = "false" ]; then
            echo "6. 🔌 Try disabling VPN temporarily"
            echo "7. 🌐 Configure VPN split tunneling to exclude local network"
        fi
        echo ""
        echo "The app has been built successfully. You can manually install it from Xcode."
        exit 1
    fi
fi
