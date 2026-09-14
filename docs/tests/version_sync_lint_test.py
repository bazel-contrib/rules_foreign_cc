import unittest

from version_sync_lint import _VERSION_TOKEN, _tag_versions


class TwoComponentGrammarTest(unittest.TestCase):
    """make ships two-component releases (4.3, 4.4) alongside 4.4.1.

    The version regexes must accept a bare `a.b` so those make versions land
    in both the accepted set (scanned from bcr_modules.bzl, whose BCR_TOOLS
    keys include "4.3" and "4.4") and the doc scan; if the grammar required
    three components, tools.make(version = "4.4") would silently never match
    and a stale 4.4 reference would pass the lint vacuously.

    There is no spoke-repo case here: make has no @make_src_<v> repo to name
    since it moved to its BCR module, and every remaining source spoke
    (cmake, meson, pkgconfig) is three-component.
    """

    def test_version_token_matches_two_and_three_component_keys(self):
        text = '"4.3": "4.4" : "4.4.1":  "4.4.x":\n"3.31.12":'
        self.assertEqual(
            [m.group(1) for m in _VERSION_TOKEN.finditer(text)],
            ["4.3", "4.4", "4.4.1", "4.4.x", "3.31.12"],
        )

    def test_version_token_ignores_values(self):
        # Only dict *keys* are tool versions. bcr_modules.bzl also holds
        # BCR_CLOSURE, whose `registry_version = "0.24.0"` (rules_cc_autoconf)
        # is a module version, not a version any tool tag may name -- without
        # the trailing-colon anchor it would be accepted as one.
        text = 'registry_version = "0.24.0",\nstrip_prefix = "make-4.4.1",'
        self.assertEqual([m.group(1) for m in _VERSION_TOKEN.finditer(text)], [])

    def test_tag_versions_picks_up_two_component_make(self):
        self.assertEqual(
            list(_tag_versions('tools.make(version = "4.4", mode = "source")')),
            ["4.4"],
        )


if __name__ == "__main__":
    unittest.main()
