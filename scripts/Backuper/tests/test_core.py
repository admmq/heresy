import unittest

from backuper.core import date_dd_mm_yy_to_iso


class DateDdMmYyToIsoTests(unittest.TestCase):
    def test_converts_valid_date(self):
        self.assertEqual(date_dd_mm_yy_to_iso("15-09-2026"), "2026-09-15")
