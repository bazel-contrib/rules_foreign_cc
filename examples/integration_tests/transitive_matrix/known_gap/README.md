# Known Gaps

This package contains stricter cases that document current differences between
foreign_cc targets and comparable native `cc_*` targets. They are not part of
the default matrix because they are expected to fail today.

The package is disabled unless the caller opts in:

```bash
bazel test //integration_tests/transitive_matrix:known_gap_tests \
  --define=transitive_cc_foreign_known_gap=true \
  --test_output=errors
```

## Cases

`:t`

Scenario: foreign_cc CMake app -> foreign_cc static libarchive -> native static
zlib.

Gap: the app declares only libarchive. The native static zlib input is present
in provider/action inputs, but is not staged as a foreign-build dependency
prefix that CMake can discover.

`:p001`

Scenario: foreign_cc shared libarchive built with native static zlib compared
to the native dynamic wrapper.

Gap: foreign_cc exposes the static zlib library through the shared libarchive
target's `CcInfo`, while the comparable native dynamic wrapper does not expose
that static library in the same way.

`:p002`

Scenario: foreign_cc shared libarchive built with foreign_cc static zlib
compared to the native dynamic wrapper.

Gap: this is the same provider-shape mismatch as above, but with the static
zlib producer coming from foreign_cc.

## Relationship To The Default Matrix

The default `cmake_static` matrix avoids the first gap by declaring both
libarchive and zlib as direct app dependencies. That verifies the app can link
and run when the final foreign build is given the complete static dependency
set.

The known-gap runtime test asks for stricter transitive behavior: a downstream
foreign_cc app should be able to depend only on static libarchive and still have
zlib staged in a way the foreign build system can link. That propagation is not
currently available.

The provider parity cases ask whether foreign shared libarchive targets expose
the same `CcInfo` shape as the native dynamic wrappers. Today they do not, so
the targets remain manual and opt-in until the intended provider contract is
clarified or changed.
