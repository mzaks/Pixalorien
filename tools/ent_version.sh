# Sourced by the release builds, from the repository's root, with
# $ENT_SRC set: the ent-lang checkout there must be at the tag in
# ENT_VERSION, so that a release is built by a known compiler. Another
# tag by $ENT_TAG; ENT_TAG= (empty) builds with whatever is there.
ENT_TAG=${ENT_TAG-$(cat ENT_VERSION)}
if [ -n "$ENT_TAG" ]; then
  ent_want=$(git -C "$ENT_SRC" rev-parse -q --verify "refs/tags/$ENT_TAG^{commit}" 2>/dev/null) || {
    echo "error: $ENT_SRC has no tag $ENT_TAG (git -C $ENT_SRC fetch --tags)" >&2
    exit 1
  }
  if [ "$(git -C "$ENT_SRC" rev-parse HEAD)" != "$ent_want" ]; then
    echo "error: $ENT_SRC is not at $ENT_TAG (git -C $ENT_SRC checkout $ENT_TAG," >&2
    echo "       or ENT_TAG= to build with what is there)" >&2
    exit 1
  fi
  echo "ent-lang $ENT_TAG"
fi
