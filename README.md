# autobookmarks

Like `recentf` but better.

# How it works

This package doesn't provide any UI, it only implements the back-end
"store" and an API you can use to retrieve the bookmarks.

The two main functions are `abm-visited-buffers` and
`abm-recent-buffers` to retrieve lists of visited and recent buffers.

This package automatically adds all killed buffers, according to
`abm-killed-buffer-functions`, to the list of recent buffers.  When
you visit a recent buffer, its associated bookmark is removed from the
recent list and moved to the visited list.  When you kill a visited
buffer, its associated bookmark is moved to the recent list.

When you visit a new buffer which is not recent it is added, according
to `abm-visited-buffer-hooks`, to the visited list.  This ensures that
newly opened buffers are stored in case of a crash.  When you restart
emacs, they will be available as recent buffers (they are not stored
as recent right away because they are active and so shouldn't be on
the recent list---that list only stores buffers which aren't visited)

You can restore a recent (killed) buffer by using
`abm-restore-killed-buffer` to which you pass the stored bookmark.

You can toggle this mode on and off by using `autobookmarks-mode`,
which is a global minor mode.

# The (lack of) UI

The author uses `sallet` package to provide seamless integration of
bookmarks with buffer switching/finding files.  You can write an `ido`
or `helm` interface fairly easily.  If someone does so, feel free to
contribute it back as a patch.

The data is stored in the same format as emacs bookmarks (`(info
"(emacs) Bookmarks")`), so it should be possible to add a bookmark
interface for it as well.
