import os
import tarfile
from datetime import date, datetime

BACKUP_INTERVAL_DAYS = 10
DEBUG = "yes"


def date_dd_mm_yy_to_iso(value: str) -> str:
    parts = value.split("-")
    if len(parts) != 3:
        raise ValueError(f"Invalid date format: {value!r}")
    return f"{parts[2]}-{parts[1]}-{parts[0]}"


class Backuper:
    def __init__(self, target_directory: str, destination_directory: str, interval_days: int = BACKUP_INTERVAL_DAYS):
        self.target_directory = target_directory
        self.destination_directory = destination_directory
        self.interval_days = interval_days
        self.today = date.today().isoformat()
        self.result = os.path.join(self.destination_directory, f"{self.today}.tar")

    def print_debug_info(self) -> None:
        if DEBUG == "yes":
            print(f"today: {self.today}")
            print(f"target_directory: {self.target_directory}")
            print(f"destination_directory: {self.destination_directory}")
            print(f"result: {self.result}")

    def latest_backup(self) -> str:
        if not os.path.isdir(self.destination_directory):
            return ""
        archives = [name for name in os.listdir(self.destination_directory) if name.endswith(".tar")]
        return sorted(archives)[-1] if archives else ""

    def days_since(self, backup_name: str) -> int | None:
        backup_date = backup_name[:-4]
        try:
            backup_dt = datetime.strptime(backup_date, "%Y-%m-%d").date()
        except ValueError:
            return None
        return (date.fromisoformat(self.today) - backup_dt).days

    def is_backup_recent(self) -> bool:
        latest_backup = self.latest_backup()
        if not latest_backup:
            return False
        days_since_last_backup = self.days_since(latest_backup)
        if days_since_last_backup is None:
            return False
        if days_since_last_backup <= self.interval_days:
            print(f"backup interval (days): {self.interval_days}")
            print(f"the last backup was recently: {latest_backup}")
            return True
        return False

    def create_archive(self) -> bool:
        print("starting backup")
        os.makedirs(self.destination_directory, exist_ok=True)

        def log_and_keep(tarinfo: tarfile.TarInfo) -> tarfile.TarInfo:
            print(tarinfo.name)
            return tarinfo

        try:
            with tarfile.open(self.result, "w") as archive:
                archive.add(
                    self.target_directory,
                    arcname=os.path.basename(self.target_directory),
                    filter=log_and_keep,
                )
        except Exception:
            print(f"something went wrong: {self.result}")
            return False

        if os.path.exists(self.result):
            print(f"backup created: {self.result}")
            return True

        print(f"something went wrong: {self.result}")
        return False

    def run(self) -> int:
        self.print_debug_info()

        if self.is_backup_recent():
            return 0

        if os.path.exists(self.result):
            print(f"backup already exists: {self.result}")
            return 0

        return 0 if self.create_archive() else 1
