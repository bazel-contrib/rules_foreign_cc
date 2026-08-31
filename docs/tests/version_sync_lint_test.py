import unittest

from version_sync_lint import _SPOKE_REPO, _VERSION_TOKEN, _tag_versions


class TwoComponentGrammarTest(unittest.TestCase):
    """make ships two-component releases (4.3, 4.4) alongside 4.4.1.

    The version/spoke regexes must accept a bare `a.b` so those make versions
    land in both the accepted set (from the data files) and the doc scan; if
    the grammar required three components, @make_src_4.4 and tools.make(
    version = "4.4") would silently never match and a stale 4.4 reference
    would pass the lint vacuously.
    """

    def test_version_token_matches_two_and_three_components(self):
        text = '"4.3" "4.4" "4.4.1" "4.4.x" "3.31.12"'
        self.assertEqual(
            [m.group(1) for m in _VERSION_TOKEN.finditer(text)],
            ["4.3", "4.4", "4.4.1", "4.4.x", "3.31.12"],
        )

    def test_spoke_repo_matches_two_component_source_release(self):
        self.assertEqual(
            [m.group(1) for m in _SPOKE_REPO.finditer("@make_src_4.4 @make_src_4.4.1")],
            ["4.4", "4.4.1"],
        )

    def test_tag_versions_picks_up_two_component_make(self):
        self.assertEqual(
            list(_tag_versions('tools.make(version = "4.4", mode = "source")')),
            ["4.4"],
        )


if __name__ == "__main__":
    unittest.main()
