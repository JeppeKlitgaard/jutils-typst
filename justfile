set minimum-version := '1.55.0'
set default-list := true

# Runs the test suite
[group: 'test']
test *args:
    tt run {{ args }}

# Updates the reference images of the given tests (all if none are given)
[group: 'test']
update *args:
    tt update {{ args }}

# Removes test output artifacts
[group: 'test']
clean:
    tt util clean
