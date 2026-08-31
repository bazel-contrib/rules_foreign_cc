# Integration Tests

Integration tests live in the example module instead of the main one because:
- We want to run them from a seperate module so they're stronger as tests, but...
- We very rapidly run into max task limits in bazelci if we matrix-generate working_directory tests.

So this is a compromise between testing and CI limits. There are certain types of test that can't be written this way
(anything testing the extensions...) but that's a problem for another day.
