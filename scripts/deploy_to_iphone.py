#!/usr/bin/env python3
"""
Health Notes - iPhone Deployment Script
This script builds and installs the latest version of the app to your connected iPhone
"""

import sys
import os
import subprocess
import json
import hashlib
import time
from typing import List, Dict, Tuple
from textwrap import dedent

# Import the base class
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from deployment_base import DeploymentBase


class IPhoneDeployment(DeploymentBase):
    """iPhone deployment implementation"""
    
    def __init__(self):
        super().__init__("iPhone", "release")
    
    def check_vpn(self) -> bool:
        """Check if VPN is active"""
        # Check for VPN interfaces
        returncode, stdout, _ = self.run_command(["ifconfig"], check=False)
        if returncode == 0 and "utun" in stdout:
            return True
        
        # Check for VPN processes
        returncode, stdout, _ = self.run_command(["pgrep", "-f", "openvpn|vpn|tunnel"], check=False)
        if returncode == 0:
            return True
        
        # Check for VPN-related network services
        returncode, stdout, _ = self.run_command(["networksetup", "-listallnetworkservices"], check=False)
        if returncode == 0 and "VPN" in stdout:
            return True
        
        return False
    
    def parse_flutter_devices(self) -> Tuple[List[Dict], List[Dict]]:
        """Parse Flutter devices output and return USB and wireless devices"""
        returncode, stdout, stderr = self.run_command(["flutter", "devices"], check=False)
        
        if returncode != 0:
            self.print_error(f"Failed to get devices: {stderr}")
            return [], []
        
        lines = stdout.split('\n')
        usb_devices = []
        wireless_devices = []
        
        for line in lines:
            line = line.strip()
            
            # Skip empty lines and headers
            if not line or line.startswith("Found") or line.startswith("Run"):
                continue
            
            # Check if this is a device line
            if "•" in line and ("mobile" in line or "ios" in line):
                parts = [p.strip() for p in line.split("•")]
                if len(parts) >= 3:
                    name = parts[0].strip()
                    device_id = parts[1].strip()
                    platform = parts[2].strip()
                    
                    # Check if it's wireless
                    is_wireless = "wireless" in line.lower()
                    
                    device_info = {
                        "name": name,
                        "id": device_id,
                        "platform": platform,
                        "is_wireless": is_wireless
                    }
                    
                    if is_wireless:
                        wireless_devices.append(device_info)
                    else:
                        usb_devices.append(device_info)
        
        return usb_devices, wireless_devices
    
    def check_iphone_trust_status(self) -> str:
        """Check if iPhone is connected but not trusted"""
        # Check if iPhone is physically connected via USB
        returncode, stdout, _ = self.run_command(["system_profiler", "SPUSBDataType"], check=False)
        if returncode != 0 or "iPhone" not in stdout:
            return "not_connected"
        
        # Check if Flutter can see it as a USB device
        usb_devices, _ = self.parse_flutter_devices()
        ios_usb_devices = [d for d in usb_devices if "ios" in d["platform"].lower()]
        
        if ios_usb_devices:
            return "usb_connected"
        else:
            return "usb_connected_not_trusted"
    
    def get_user_choice(self, prompt: str, options: List[str]) -> str:
        """Get user choice from a list of options"""
        print(f"\n{prompt}")
        for i, option in enumerate(options, 1):
            print(f"{i}) {option}")
        
        while True:
            try:
                choice = input(f"\nEnter your choice (1-{len(options)}): ").strip()
                choice_num = int(choice)
                if 1 <= choice_num <= len(options):
                    return options[choice_num - 1]
            except ValueError:
                pass
            print(f"Please enter a number between 1 and {len(options)}")
    
    def handle_vpn_warning(self) -> bool:
        """Handle VPN detection and get user choice"""
        self.print_warning("VPN Detected - This may interfere with wireless device connections")
        print("=" * 64)
        print(dedent("""
            VPNs can block local network discovery needed for wireless iPhone deployment.
            However, USB connections work fine with VPN.

            Solutions:
            1. 🔌 Disconnect VPN temporarily and try again
            2. 🔗 Connect iPhone via USB cable (recommended with VPN)
            3. 🌐 Add your local network to VPN split tunneling (if supported)
            4. 📱 Use iOS Simulator instead"""))
        
        options = [
            "Continue with wireless deployment (may fail)",
            "Build for USB deployment (connect iPhone via cable)",
            "Deploy to iOS Simulator instead",
            "Exit and fix VPN settings"
        ]
        
        choice = self.get_user_choice("Would you like to:", options)
        
        if "wireless" in choice:
            return True
        elif "USB" in choice:
            input("Please connect your iPhone via USB cable before continuing. Press Enter when ready...")
            return True
        elif "Simulator" in choice:
            print("Switching to iOS Simulator deployment...")
            self.run_command(["./scripts/deploy_to_simulator.py"])
            return False
        else:
            print("Exiting. Please disable VPN or configure split tunneling and try again.")
            return False
    
    def handle_trust_issue(self) -> bool:
        """Handle iPhone trust issue"""
        self.print_warning("iPhone Connected but Not Trusted")
        print("=" * 35)
        print(dedent("""
            Your iPhone is connected via USB, but Flutter cannot access it.
            This usually means the iPhone needs to be trusted.

            Please:
            1. Unlock your iPhone
            2. Look for a 'Trust This Computer?' dialog on your iPhone
            3. Tap 'Trust' and enter your iPhone passcode
            4. If no dialog appears, go to Settings > General > VPN & Device Management
               and tap 'Trust' next to your Mac"""))
        
        input("\nPress Enter when you've trusted your Mac...")
        
        print("\nRechecking device connection...")
        return True
    
    def install_to_device(self, device_id: str) -> bool:
        """Install the app to a specific device"""
        self.print_info(f"Installing to iPhone (ID: {device_id})...")
        
        returncode, _, stderr = self.run_command([
            "flutter", "install", "--release", "-d", device_id
        ], check=False)
        
        if returncode == 0:
            self.print_success("Deployment complete! 🎉")
            print(dedent("""
                Your Health Notes app has been updated on your iPhone.
                You can now disconnect your phone and use the app anywhere."""))
            return True
        else:
            self.print_error("Installation failed!")
            print(dedent("""
                Troubleshooting tips:
                1. Make sure your iPhone is unlocked
                2. Check that you've trusted your Mac on your iPhone
                3. Ensure Developer Mode is enabled on your iPhone"""))
            return False
    
    def deploy(self) -> bool:
        """Deploy the app to iPhone"""
        self.print_info("Checking for connected devices...")
        print()
        
        # Get device information
        usb_devices, wireless_devices = self.parse_flutter_devices()
        vpn_active = self.check_vpn()
        
        # Print device information
        returncode, stdout, _ = self.run_command(["flutter", "devices"], check=False)
        print(stdout)
        
        # Check for trust issues
        trust_status = self.check_iphone_trust_status()
        if trust_status == "usb_connected_not_trusted":
            if not self.handle_trust_issue():
                return False
            # Recheck devices after trust
            usb_devices, wireless_devices = self.parse_flutter_devices()
            returncode, stdout, _ = self.run_command(["flutter", "devices"], check=False)
            print(stdout)
        
        # Handle VPN warnings only if no USB devices and wireless issues
        if vpn_active and not usb_devices and wireless_devices:
            if not self.handle_vpn_warning():
                return False
        
        # Install to device
        if usb_devices:
            # Use the first USB device
            device_id = usb_devices[0]["id"]
            return self.install_to_device(device_id)
        else:
            self.print_info("Installing to iPhone...")
            print("Please select your iPhone when prompted:")
            
            returncode, _, stderr = self.run_command(["flutter", "install", "--release"], check=False)
            if returncode == 0:
                self.print_success("Deployment complete! 🎉")
                print(dedent("""
                    Your Health Notes app has been updated on your iPhone.
                    You can now disconnect your phone and use the app anywhere."""))
                return True
            else:
                self.print_error("Installation failed!")
                print(dedent("""
                    Troubleshooting tips:
                    1. Make sure your iPhone is unlocked
                    2. Check that you've trusted your Mac on your iPhone
                    3. Try connecting your iPhone via USB cable
                    4. Ensure Developer Mode is enabled on your iPhone
                    5. Check that both devices are on the same WiFi network"""))
                if vpn_active:
                    print(dedent("""
                        6. 🔌 Try disabling VPN temporarily
                        7. 🌐 Configure VPN split tunneling to exclude local network"""))
                print("\nThe app has been built successfully. You can manually install it from Xcode.")
                return False


def main():
    """Main function"""
    deployment = IPhoneDeployment()
    deployment.main()


if __name__ == "__main__":
    main()
