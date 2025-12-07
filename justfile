default:
    @just -l

tag VERSION:
    git tag -a -m "v${VERSION}" "v${VERSION}"
