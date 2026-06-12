import hashlib
import io
import unittest
from unittest import mock

import prebuilt_toolchains
from prebuilt_toolchains import (
    add_source_wildcards,
    hashed_source_versions,
    latest_cmake_patch,
    latest_ninja_patches,
    render_source_dict,
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


class RenderSourceDictStripPrefixTest(unittest.TestCase):
    def test_x_alias_reuses_exact_patch_strip_prefix(self):
        # The `.x` alias entry shares the exact-patch entry's explicit
        # strip_prefix. render_source_dict must emit that prefix verbatim,
        # NOT derive "cmake-3.19.x" from the alias key -- the archive unpacks
        # to "cmake-3.19.8" regardless of which key reached it.
        entry = {
            "urls": ["https://example/cmake-3.19.8.tar.gz"],
            "strip_prefix": "cmake-3.19.8",
            "sha256": "deadbeef",
            "patches": [],
        }
        versions = {"3.19.8": entry, "3.19.x": entry}
        out = render_source_dict(
            varname="CMAKE_SRC_SRCS",
            url_template="",
            fallback_template=None,
            versions=versions,
            prefix_template="cmake-{version}",
        )
        # Both the exact key and the wildcard key carry the patch-dir prefix.
        self.assertEqual(out.count('strip_prefix = "cmake-3.19.8"'), 2)
        # The buggy key-derived prefix must never appear.
        self.assertNotIn("cmake-3.19.x", out)

    def test_falls_back_to_template_without_explicit_prefix(self):
        # When no explicit strip_prefix is set, the key-derived template is used.
        versions = {
            "4.4.1": {
                "urls": ["https://example/make-4.4.1.tar.gz"],
                "sha256": "abc",
                "patches": [],
            }
        }
        out = render_source_dict(
            varname="GNUMAKE_SRCS",
            url_template="",
            fallback_template=None,
            versions=versions,
            prefix_template="make-{version}",
        )
        self.assertIn('strip_prefix = "make-4.4.1"', out)


class AddSourceWildcardsTest(unittest.TestCase):
    def test_make_irregular_versions_resolve_to_latest_patch(self):
        # make ships 4.3, 4.4, and 4.4.1. The old built_toolchains.bzl accepted
        # 4.3.x -> 4.3 and 4.4.x -> 4.4.1 (latest in the 4.4 series), while 4.4
        # stayed exact-only. Reproduce that contract.
        versions = {
            "4.3": {"sha256": "a", "patches": ["p43"]},
            "4.4": {"sha256": "b", "patches": ["p44"]},
            "4.4.1": {"sha256": "c", "patches": ["p441"]},
        }
        out = add_source_wildcards(
            versions,
            "u/make-{version}.tar.gz",
            "f/make-{version}.tar.gz",
            "make-{version}",
        )
        self.assertEqual(out["4.3.x"]["sha256"], "a")
        self.assertEqual(out["4.3.x"]["strip_prefix"], "make-4.3")
        self.assertEqual(out["4.4.x"]["sha256"], "c")
        self.assertEqual(out["4.4.x"]["strip_prefix"], "make-4.4.1")
        # The exact keys are preserved untouched and 4.4 gets no wildcard of
        # its own (4.4.x points past it at 4.4.1).
        self.assertEqual(set(out), {"4.3", "4.4", "4.4.1", "4.3.x", "4.4.x"})

    def test_derives_urls_when_entry_has_none(self):
        # Entries without explicit urls (make/meson/pkgconfig) must get urls
        # synthesized from the resolved exact patch, never "make-4.4.x".
        out = add_source_wildcards(
            {"4.4.1": {"sha256": "c", "patches": []}},
            "u/make-{version}.tar.gz",
            None,
            "make-{version}",
        )
        self.assertEqual(out["4.4.x"]["urls"], ["u/make-4.4.1.tar.gz"])

    def test_preserves_explicit_urls(self):
        # Entries with explicit urls (ninja, incl. 1.13.2's no-mirror case)
        # carry them onto the alias verbatim.
        out = add_source_wildcards(
            {"1.13.2": {"urls": ["only/v1.13.2.tar.gz"], "integrity": "i"}},
            "",
            None,
            "ninja-{version}",
        )
        self.assertEqual(out["1.13.x"]["urls"], ["only/v1.13.2.tar.gz"])
        self.assertEqual(out["1.13.x"]["integrity"], "i")


class Sha256OfTest(unittest.TestCase):
    def test_hashes_returned_bytes(self):
        # Streams the body and hashes the actual returned bytes (not the
        # requested chunk size, which the old loop miscounted).
        payload = b"hello ninja" * 1000
        with mock.patch.object(
            prebuilt_toolchains.urllib.request,
            "urlopen",
            return_value=io.BytesIO(payload),
        ):
            self.assertEqual(
                prebuilt_toolchains._sha256_of("http://x"),
                hashlib.sha256(payload).hexdigest(),
            )

    def test_raises_over_cap_instead_of_truncating(self):
        # A stream past the cap must raise, not silently hash a prefix and
        # bake a wrong, non-reproducible sha256 into the generated data.
        big = b"x" * (prebuilt_toolchains._MAX_HASH_BYTES + 1)
        with mock.patch.object(
            prebuilt_toolchains.urllib.request,
            "urlopen",
            return_value=io.BytesIO(big),
        ):
            with self.assertRaises(RuntimeError):
                prebuilt_toolchains._sha256_of("http://big")


class HashedSourceVersionsTest(unittest.TestCase):
    def test_templates_both_urls_and_hashes_first_reachable(self):
        # Each version expands to [mirror, fallback] and the sha256 is hashed
        # from whichever url is reachable -- no hand-pasted digest.
        with mock.patch.object(
            prebuilt_toolchains, "_sha256_of_first", return_value="deadbeef"
        ) as hasher:
            out = hashed_source_versions(
                "meson",
                {"1.10.1": []},
                "https://mirror/meson-{version}.tar.gz",
                "https://upstream/meson-{version}.tar.gz",
            )
        self.assertEqual(
            out["1.10.1"]["urls"],
            [
                "https://mirror/meson-1.10.1.tar.gz",
                "https://upstream/meson-1.10.1.tar.gz",
            ],
        )
        self.assertEqual(out["1.10.1"]["sha256"], "deadbeef")
        # The hasher is handed the mirror-first url list, not a single url.
        hasher.assert_called_once_with(
            [
                "https://mirror/meson-1.10.1.tar.gz",
                "https://upstream/meson-1.10.1.tar.gz",
            ]
        )

    def test_carries_patches_through(self):
        with mock.patch.object(
            prebuilt_toolchains, "_sha256_of_first", return_value="abc"
        ):
            out = hashed_source_versions(
                "make",
                {"4.3": ["//toolchains/patches:make-4.3-reproducible-bootstrap.patch"]},
                "https://mirror/make-{version}.tar.gz",
                None,
            )
        self.assertEqual(
            out["4.3"]["patches"],
            ["//toolchains/patches:make-4.3-reproducible-bootstrap.patch"],
        )
        # No fallback template -> only the mirror url.
        self.assertEqual(out["4.3"]["urls"], ["https://mirror/make-4.3.tar.gz"])


class Sha256OfFirstTest(unittest.TestCase):
    def test_falls_through_404_mirror_to_upstream(self):
        # A version with no mirror copy yet (e.g. fresh ninja 1.13.2) 404s past
        # the mirror; the digest comes from the upstream url instead.
        payload = b"ninja-archive"
        urls = ["https://mirror/v1.13.2.tar.gz", "https://upstream/v1.13.2.tar.gz"]

        def fake_urlopen(url):
            if "mirror" in url:
                raise urllib_error()
            return io.BytesIO(payload)

        prebuilt_toolchains._SHA_CACHE.clear()
        with mock.patch.object(
            prebuilt_toolchains.urllib.request, "urlopen", side_effect=fake_urlopen
        ):
            self.assertEqual(
                prebuilt_toolchains._sha256_of_first(urls),
                hashlib.sha256(payload).hexdigest(),
            )

    def test_raises_when_no_url_reachable(self):
        prebuilt_toolchains._SHA_CACHE.clear()
        with mock.patch.object(
            prebuilt_toolchains.urllib.request,
            "urlopen",
            side_effect=urllib_error(),
        ):
            with self.assertRaises(RuntimeError):
                prebuilt_toolchains._sha256_of_first(["https://a", "https://b"])


def urllib_error():
    import urllib.error

    return urllib.error.HTTPError("u", 404, "Not Found", hdrs=None, fp=None)


if __name__ == "__main__":
    unittest.main()
