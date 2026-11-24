import doctest
import importlib
import inspect
import pkgutil
import unittest

import cmrdesign as cmr


class DocstringTests(unittest.TestCase):
    def test_every_public_function_documents_parameters_and_returns(self):
        for name in cmr.__all__:
            obj = getattr(cmr, name)
            doc = inspect.getdoc(obj) or ""
            with self.subTest(name=name):
                self.assertTrue(doc.strip(), f"{name} has no docstring")
                if inspect.isfunction(obj):
                    self.assertIn("Parameters", doc)
                    self.assertIn("Returns", doc)

    def test_documented_parameters_match_signatures(self):
        for name in cmr.__all__:
            obj = getattr(cmr, name)
            if not inspect.isfunction(obj):
                continue
            doc = inspect.getdoc(obj) or ""
            section = doc.split("Parameters", 1)[1].split("Returns", 1)[0]
            documented = set()
            for line in section.splitlines():
                if " : " in line and not line.startswith(" "):
                    documented.update(
                        part.strip() for part in line.split(" : ")[0].split(",")
                    )
            with self.subTest(name=name):
                self.assertEqual(documented, set(inspect.signature(obj).parameters))

    def test_docstring_examples_run(self):
        failures = 0
        for module in pkgutil.iter_modules(cmr.__path__):
            loaded = importlib.import_module(f"cmrdesign.{module.name}")
            failures += doctest.testmod(loaded).failed
        self.assertEqual(failures, 0)

    def test_version_matches_installed_metadata(self):
        from importlib.metadata import version

        self.assertEqual(cmr.__version__, version("cmrdesign"))


if __name__ == "__main__":
    unittest.main()
