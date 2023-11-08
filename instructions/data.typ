// This module deals with accessing the filesystem.

// Returns a new dictionary from the given array of key-value pairs.
#let make_dict(pairs) = {
  let dict = (:)
  for (k, v) in pairs {
    dict.insert(k, v)
  }
  dict
}

// Test for `make_dict`.
#for (input, expected) in (
  ((), (:)),
  ((("one", 1),), (one: 1)),
  ((("one", 1), ("two", 2), ("three", 3)), (one: 1, two: 2, three: 3)),
) {
  let actual = make_dict(input)
  assert(
    actual == expected,
    message: "expected " + repr(expected) + " but got " + repr(actual),
  )
}

// The contents of "../boot-dvd/internal/hashes.txt" as a dictionarry mapping
// from names to strings.
#let known_hashes = {
  make_dict(
    read("../boot-dvd/internal/hashes.txt")
      .split("\n")
      .filter(line => line != "")
      .map(line => line.split("="))
  )
}

// Returns the contents of a `sha256sum`-formatted file, as a dictionarry
// mapping from file paths to hashes.
#let read_sha256sums(filename) = {
  make_dict(
    read(filename)
      .split("\n")
      .filter(line => line != "")
      .map(line => line.split("  "))
      .map(((hash, path)) => (path, hash))
  )
}

// The SHA-256 hash of the boot DVD ISO image.
#let boot_dvd_sha256 = {
  read_sha256sums("../boot-dvd/sha256sum.output.txt")
    .at("./target/live-build/ceremony-boot-amd64.iso")
}

// The SHA-1 hash of the current git HEAD commit.
#let git_commit_hash = {
    // Normally, '../.git/HEAD' contains the name of a branch ref, but in the
    // "detached HEAD" state, it instead contains a commit hash.
    //
    // Ref names in Git are restricted in complex ways, which are only
    // approximated here for safety during path traversal. See
    // https://git-scm.com/docs/git-check-ref-format
    let head = read("../.git/HEAD").trim("\n", at: end)
    let match = head.match(regex(
      "^ref: (refs/heads/[A-Za-z0-9\+,\-\./_]+)$"
    ))
    let hash = if match == none {
      head
    } else {
      let ref = match.captures.at(0)
      assert(not ref.contains(".."))
      assert(not ref.contains("/."))
      read("../.git/" + ref).trim("\n", at: end)
    }
    assert(hash.contains(regex("^[0-9a-f]{40}$")))
    hash
}
