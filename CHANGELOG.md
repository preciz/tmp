# Changelog

## v0.3.0

* Breaking: Tmp is no longer an application, it's now a supervisor that you can add to your application's supervision tree
* Breaking: Removed `keep` functionality

## v0.2.0


* Remove `:dirname` option in favor of always random dirnames, and add `:prefix` option instead.
* Remove usage of `keep.()` function and use `Tmp.keep()` instead to keep the temporary directory

