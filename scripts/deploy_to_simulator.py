#!/usr/bin/env python3
"""
Health Notes - iOS Simulator Deployment Script
This script builds and installs the latest version of the app to the iOS Simulator
"""

import sys
import os
import time
from textwrap import dedent

# Import the base class
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from deployment_base import DeploymentBase


class SimulatorDeployment(DeploymentBase):
    """iOS Simulator deployment implementation"""
    
    def __init__(self):
        super().__init__("Simulator", "debug")
    
    def start_simulator(self) -> bool:
        """Start the iOS Simulator"""
        self.print_info("Starting iOS Simulator...")
        
        # Start the simulator
        returncode, _, stderr = self.run_command(["open", "-a", "Simulator"], check=False)
        if returncode != 0:
            self.print_error(f"Failed to start simulator: {stderr}")
            return False
        
        # Wait a moment for simulator to start
        print("Waiting for simulator to start...")
        time.sleep(3)
        return True
    
    def install_to_simulator(self) -> bool:
        """Install the app to the iOS Simulator"""
        self.print_info("Installing to iOS Simulator...")
        
        returncode, _, stderr = self.run_command(["flutter", "install"], check=False)
        if returncode == 0:
            self.print_success("Deployment complete! 🎉")
            print(dedent("""
                Your Health Notes app has been installed on the iOS Simulator.
                The simulator should now be running with your app."""))
            return True
        else:
            self.print_error(f"Installation failed: {stderr}")
            return False
    
    def deploy(self) -> bool:
        """Deploy the app to iOS Simulator"""
        # Start simulator
        if not self.start_simulator():
            return False
        
        # Install to simulator
        return self.install_to_simulator()


def main():
    """Main function"""
    deployment = SimulatorDeployment()
    deployment.main()


if __name__ == "__main__":
    main()
