#!/usr/bin/env python3
"""
Health Notes - iPhone Deployment Script (Simplified)

A lean, reliable installer for deploying the app to a real iPhone.
Focuses on:
- Single responsibility: discover device(s) and install
- Clear, minimal flow with small helpers
- Delegates heavy lifting (build, checks, caching) to DeploymentBase
"""

import os
import sys
from typing import List, Dict
from textwrap import dedent

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from deployment_base import DeploymentBase


class IPhoneDeployment(DeploymentBase):
    """iPhone deployment with minimal branching and clear steps."""

    def __init__(self):
        super().__init__("iPhone", "release")

    # ----- Device Discovery -----
    def _vpn_active(self) -> bool:
        """Heuristic check for active VPN (best-effort, non-intrusive)."""
        # utun interfaces are commonly present when a VPN is active
        code, out, _ = self.run_command(["ifconfig"], check=False)
        if code == 0 and "utun" in (out or ""):
            return True

        # Look for common VPN client processes
        code, out, _ = self.run_command([
            "pgrep", "-f",
            "openvpn|wireguard|tailscale|zerotier|expressvpn|nordvpn|protonvpn|anyconnect|cisco|tunnel"
        ], check=False)
        if code == 0 and (out or "").strip():
            return True

        # System network connections listing (may show Connected VPNs)
        code, out, _ = self.run_command(["scutil", "--nc", "list"], check=False)
        if code == 0 and "Connected" in (out or ""):
            return True

        return False

    def _list_ios_devices(self) -> List[Dict[str, str]]:
        """Return a list of PHYSICAL iOS devices from `flutter devices` output.

        Output example line:
        "Ethan’s iPhone • 00008030-... • ios • iOS 17.5"
        """
        code, stdout, stderr = self.run_command(["flutter", "devices"], check=False)
        if code != 0:
            self.print_error(f"Failed to list devices: {stderr}")
            return []

        devices: List[Dict[str, str]] = []
        for line in stdout.splitlines():
            if "•" not in line:
                continue
            parts = [p.strip() for p in line.split("•")]
            if len(parts) < 3:
                continue
            name, device_id, platform = parts[0], parts[1], parts[2]
            lower_line = line.lower()
            lower_platform = platform.lower()

            # Skip simulators explicitly
            if "simulator" in lower_line or "com.apple.coresimulator" in lower_platform:
                continue

            # Keep only physical iOS devices (USB or wireless)
            if "ios" in lower_platform or "mobile" in lower_platform:
                devices.append({"name": name, "id": device_id})
        return devices

    def _simulators_present(self) -> bool:
        """Return True if any iOS simulators are listed by Flutter."""
        code, stdout, _ = self.run_command(["flutter", "devices"], check=False)
        if code != 0:
            return False
        for line in stdout.splitlines():
            if "ios" in line.lower() and "simulator" in line.lower():
                return True
        return False

    # ----- Installation -----
    def _install_interactive(self) -> bool:
        self.print_info("Installing to iPhone (interactive selection)...")
        code = self.run_command_streaming(["flutter", "install", "--release"], check=False)
        if code == 0:
            self._print_success_note()
            return True
        self.print_error("Installation failed.")
        return False

    def _install_to_device(self, device_id: str) -> bool:
        self.print_info(f"Installing to iPhone: -d {device_id}")
        code = self.run_command_streaming(["flutter", "install", "--release", "-d", device_id], check=False)
        if code == 0:
            self._print_success_note()
            return True
        self.print_error("Installation failed.")
        return False

    def _print_success_note(self):
        self.print_success("Deployment complete! 🎉")
        print(dedent(
            """
            Your Health Notes app has been updated on your iPhone.
            You can now disconnect your phone and use the app anywhere.
            """
        ))

    # ----- Orchestration -----
    def deploy(self) -> bool:
        """Discover devices and install with the simplest possible logic."""
        if self._vpn_active():
            self.print_warning("VPN likely active — wireless install may fail. Prefer USB.")

        self.print_info("Checking for iOS devices...")
        devices = self._list_ios_devices()

        if len(devices) == 1:
            return self._install_to_device(devices[0]["id"])

        if not devices:
            if self._simulators_present():
                self.print_warning("Only iOS simulators detected. Use scripts/deploy_to_simulator.py for simulator.")
                return False
            self.print_warning("No physical iPhone detected. Flutter may still prompt if one appears.")
            return self._install_interactive()

        # Multiple physical devices: let Flutter prompt to choose
        self.print_info("Multiple iPhones detected. Select one in the prompt.")
        return self._install_interactive()


def main():
    deployment = IPhoneDeployment()
    deployment.main()


if __name__ == "__main__":
    main()
