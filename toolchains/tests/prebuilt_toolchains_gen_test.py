import unittest
from unittest import mock

import prebuilt_toolchains
from prebuilt_toolchains import (
    _trailing_commas,
    latest_cmake_patch,
    latest_ninja_patches,
    version_condition,
)

_CMAKE_DIR_LISTING = """\
<a href="cmake-3.19.0.tar.gz">cmake-3.19.0.tar.gz</a>
<a href="cmake-3.19.0-SHA-256.txt">cmake-3.19.0-SHA-256.txt</a>
<a href="cmake-3.19.8.tar.gz">cmake-3.19.8.tar.gz</a>
<a href="cmake-3.19.2.tar.gz">cmake-3.19.2.tar.gz</a>
<a href="cmake-3.19.10.tar.gz">cmake-3.19.10.tar.gz</a>
"""

_NINJA_RELEASES_JSON = """\
[
  {"tag_name": "v1.13.2"},
  {"tag_name": "v1.13.0"},
  {"tag_name": "v1.12.1"},
  {"tag_name": "v1.11.1"},
  {"tag_name": "v1.13.1"}
]
"""


class LatestCmakePatchTest(unittest.TestCase):
    def test_takes_max_patch_from_listing(self):
        with mock.patch.object(
            prebuilt_toolchains, "_fetch", return_value=_CMAKE_DIR_LISTING
        ):
            self.assertEqual(latest_cmake_patch("3.19"), "3.19.10")

    def test_raises_when_series_absent(self):
        with mock.patch.object(prebuilt_toolchains, "_fetch", return_value=""):
            with self.assertRaises(RuntimeError):
                latest_cmake_patch("9.99")


class LatestNinjaPatchesTest(unittest.TestCase):
    def test_resolves_all_minors_from_one_listing(self):
        with mock.patch.object(
            prebuilt_toolchains, "_fetch", return_value=_NINJA_RELEASES_JSON
        ) as fetch:
            result = latest_ninja_patches(("1.13", "1.12", "1.11"))
        self.assertEqual(result, {"1.13": "1.13.2", "1.12": "1.12.1", "1.11": "1.11.1"})
        # A single network request covers every minor.
        self.assertEqual(fetch.call_count, 1)

    def test_raises_when_minor_absent(self):
        with mock.patch.object(
            prebuilt_toolchains, "_fetch", return_value=_NINJA_RELEASES_JSON
        ):
            with self.assertRaises(RuntimeError):
                latest_ninja_patches(("1.99",))


class TrailingCommasTest(unittest.TestCase):
    def test_adds_commas_to_nested_closers(self):
        src = '{\n    "a": [\n        "x"\n    ]\n}'
        expected = '{\n    "a": [\n        "x",\n    ],\n}'
        self.assertEqual(_trailing_commas(src), expected)

    def test_leaves_inline_collections_untouched(self):
        self.assertEqual(_trailing_commas('{"a": "b"}'), '{"a": "b"}')


class VersionConditionTest(unittest.TestCase):
    def test_compound_condition_includes_wildcard_and_exact(self):
        self.assertEqual(
            version_condition("3.19", "3.19.8"),
            '    if "3.19.x" == version or "3.19.8" == version:',
        )


if __name__ == "__main__":
    unittest.main()
