import argparse
import os
import sys

from .core import Backuper


def is_admin() -> bool:
    if sys.platform == "win32":
        import ctypes

        try:
            return bool(ctypes.windll.shell32.IsUserAnAdmin())
        except OSError:
            return False
    return os.geteuid() == 0


def parse_args() -> argparse.Namespace:
    if sys.platform == "win32":
        elevate_tip = "this command must be run as an administrator"
    else:
        elevate_tip = "this command must be run as root"
    default_target = os.path.join(os.path.expanduser("~"), "Downloads")
    default_destination = os.path.join(os.path.expanduser("~"), "Backuper")

    parser = argparse.ArgumentParser(
        description="Back up a directory into a dated tar archive.",
        epilog=elevate_tip,
    )
    parser.add_argument("target_directory", 
                        nargs="?", 
                        default=default_target, 
                        help="directory to back up")
    parser.add_argument("destination_directory", 
                        nargs="?", 
                        default=default_destination, 
                        help="directory to store backups in")
    return parser.parse_args()


def main() -> int:
    args = parse_args()

    if not is_admin():
        if sys.platform == "win32":
            print("This script must be run as an administrator.")
        else:
            print("This script must be run as root. Please use 'sudo'.")
        return 1

    backuper = Backuper(
        target_directory=args.target_directory,
        destination_directory=args.destination_directory,
    )
    return backuper.run()
