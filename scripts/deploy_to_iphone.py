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
from typing import Dict, List, Optional

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from deployment_base import DeploymentBase


class IPhoneDeployment(DeploymentBase):
    """iPhone deployment with minimal branching and clear steps."""

    def __init__(self):
        super().__init__("iPhone", "release")

    # ----- Device Discovery -----
    def _read_command(self, command: List[str]) -> Optional[str]:
        """Run a command and return stdout when successful."""
        code, stdout, _ = self.run_command(command, check=False)
        return stdout or "" if code == 0 else None

    def _list_ios_devices(self) -> List[Dict[str, str]]:
        """Return a list of PHYSICAL iOS devices from `flutter devices` output.

        Output example line:
        "Ethan’s iPhone • 00008030-... • ios • iOS 17.5"
        """
        code, stdout, stderr = self.run_command(["flutter", "devices"], check=False)
        if code != 0:
            raise RuntimeError(f"Failed to list devices: {stderr.strip() or stdout.strip()}")

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

    # ----- Installation -----
    def _install_to_device(self, device_id: str) -> None:
        self.print_info(f"Installing to iPhone: -d {device_id}")
        code = self.run_command_streaming(["flutter", "install", "--release", "-d", device_id],
                                          check=False)

        if code != 0:
            raise RuntimeError("Installation failed. See flutter install output above for details.")

        self.print_success("Deployment complete! 🎉")

    # ----- Orchestration -----
    def deploy(self) -> None:
        """Discover devices and install with the simplest possible logic."""
        self.print_warning("VPN detection does not work. Disable any active VPN to prevent "
                           "deployment from stalling indefinitely after the build completes.")
        self.print_info("Checking for iOS devices...")
        devices = self._list_ios_devices()

        if len(devices) != 1:
            if not devices:
                raise RuntimeError(
                    "No physical iPhone detected. Unlock and connect via USB or Wi-Fi and retry."
                )

            device_list = "\n".join(f"  • {device['name']} ({device['id']})" for device in devices)
            raise RuntimeError(
                "Multiple physical iPhones detected. Disconnect extra devices before deploying.\n"
                f"Detected devices:\n{device_list}"
            )

        self._install_to_device(devices[0]["id"])


if __name__ == "__main__":
    IPhoneDeployment().main()
