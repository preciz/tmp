# Changelog

## v0.3.1

* Raise if no Monitor process running
* Update ex_doc to 0.36
* Update dependencies
* Add more tests
* Documentation updates

## v0.3.0

* Breaking: Tmp is no longer an application, it's now a supervisor that you can add to your application's supervision tree, see the updated README for more information.
* Breaking: Removed `keep` functionality. (If required it's best to handle this in your own code)

## v0.2.0


* Remove `:dirname` option in favor of always random dirnames, and add `:prefix` option instead.
* Remove usage of `keep.()` function and use `Tmp.keep()` instead to keep the temporary directory

