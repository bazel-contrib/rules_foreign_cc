import unittest
from unittest import mock

import prebuilt_toolchains
from prebuilt_toolchains import (
    latest_cmake_patch,
    latest_ninja_patches,
    render_wildcard_map,
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


class RenderWildcardMapTest(unittest.TestCase):
    def test_maps_minor_wildcard_to_exact_patch(self):
        # render_binary_dict-style input: {version: {plat: ...}}.
        versions = {"3.31.12": {}, "3.30.9": {}}
        out = render_wildcard_map("CMAKE_BIN_WILDCARDS", versions)
        self.assertIn('"3.31.x": "3.31.12"', out)
        self.assertIn('"3.30.x": "3.30.9"', out)


if __name__ == "__main__":
    unittest.main()
