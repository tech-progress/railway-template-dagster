import os
from pathlib import Path
import subprocess
import tempfile
import unittest


class StartTest(unittest.TestCase):
    def test_database_url_selects_the_installed_driver(self) -> None:
        template_root = Path(__file__).resolve().parents[1]
        for scheme in ("postgres", "postgresql", "postgresql+psycopg2"):
            with self.subTest(scheme=scheme), tempfile.TemporaryDirectory() as directory:
                executable_dir = Path(directory)
                for name, body in (
                    ("dagster", "exit 0"),
                    ("dagster-webserver", 'printf "%s" "$DATABASE_URL"'),
                ):
                    executable = executable_dir / name
                    executable.write_text(f"#!/bin/sh\n{body}\n")
                    executable.chmod(0o755)
                environment = {
                    **os.environ,
                    "PATH": f"{executable_dir}:{os.environ['PATH']}",
                    "DATABASE_URL": f"{scheme}://user:password@host:5432/database?sslmode=require",
                }
                result = subprocess.run(
                    ["bash", str(template_root / "scripts/start.sh"), "webserver"],
                    env=environment,
                    check=True,
                    capture_output=True,
                    text=True,
                )
                self.assertEqual(
                    result.stdout,
                    "postgresql+psycopg2://user:password@host:5432/database?sslmode=require",
                )
