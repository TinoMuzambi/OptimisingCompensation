import csv
from pathlib import Path
import unittest


ROOT = Path(__file__).parents[1]


class RepositoryTests(unittest.TestCase):
    def test_experiment_csv_files_have_expected_schema_and_rows(self) -> None:
        csv_files = sorted((ROOT / "data").glob("??-*.csv"))
        self.assertGreaterEqual(len(csv_files), 10)
        for path in csv_files:
            with path.open(encoding="utf-8-sig", newline="") as handle:
                reader = csv.DictReader(handle)
                self.assertEqual(reader.fieldnames, ["Ticks", "placeholder", "Changers", "Stayers"])
                self.assertIsNotNone(next(reader, None), f"{path.name} must contain data")

    def test_model_contains_corrected_agent_invariants(self) -> None:
        model = (ROOT / "Optimising Compensation.nlogo").read_text(encoding="utf-8")
        self.assertIn("set my-employer nobody", model)
        self.assertIn("if old-employer != nobody", model)
        self.assertEqual(model.count("set tenure tenure + 1"), 2)
        self.assertNotIn("10000000", model)

    def test_analysis_uses_basenames_and_valid_patterns(self) -> None:
        analysis = (ROOT / "Optimising Compensation Analysis.Rmd").read_text(encoding="utf-8")
        self.assertEqual(analysis.count("str_extract(basename("), 3)
        for suffix in ("average-salaries", "inflation", "employers"):
            self.assertIn(suffix, analysis)
        self.assertNotIn('"*employers"', analysis)


if __name__ == "__main__":
    unittest.main()
