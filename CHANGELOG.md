## v0.16.1
* Change `RedisStorage` scrub to be iterative to avoid SystemStackError while cleaning big experiments

## v0.16.0
* Allow configuring the `RedisStorage` with a [`ConnectionPool`](https://github.com/mperham/connection_pool) instead of a raw `Redis` connection.

## v0.15.2
* Fix edge case where inheriting from `Verdict::Experiment` and overriding `subject_qualifies?` resulted in an error.

## v0.15.1
* Make the `dynamic_qualifies` parameter in `Verdict::Experiment#subject_qualifies?` optional. This fixes a bug where users that were previously calling this method directly experienced issues after v0.15.0

## v0.15.0
* Add optional `qualifiers` parameter to the `Verdict::Experiment#switch` method. This parameter accepts an array of procs and is used as additional qualifiers. The purpose of this parameter is to allow users to define qualification logic outside of the experiment definition.

## v0.14.0
* Add optional experiment definition method `schedule_stop_new_assignment_timestamp` to support limiting experiment's assignment lifetime with another pre-determined time interval. It allows users to have an assignment cooldown period for stable analysis of the experiment results. Experiment's lifetime now becomes: start experiment -> stop new assignments -> end experiment. 

## v0.13.0

* Add optional experiment definition methods `schedule_start_timestamp` and `schedule_end_timestamp` to support limiting experiment's lifetime in a pre-determined time interval.
* Support eager loading from within a Rails app using Zeitwerk.
* Add `CookieStorage` storage backend. This backend is a distributed store for Verdict and does not support experiment timestamps. It is designed to be used with Rails applications and requires that `.cookies` be set to the `CookieJar` instance before use.

## v0.12.0

* Allow options to be passed to `Experiment#cleanup` so they can be forwarded to storage.

* Changed `Experiment#cleanup` to accept an argument of type `Verdict::Experiment`.
  Passing a `String`/`Symbol` argument is still supported, but will log a deprecation warning.

## v0.11.0

* Automatic eager loading when inside a Rails app.

## v0.10.0

* Add `Experiment#cleanup` to remove stored redis hashes.
* Fix typo in `Experiment#fetch_subject` error message.

## v0.9.0
**This version has breaking changes**

* Eagerly load experiment definitions when booting Rails, so that multi-threaded applications do not face a race-condition when populating experiments.
* Fixes deprecated `assert_equal` tests that return nil.

## v0.8.0
**This version has breaking changes**

* Experiments that have `store_unqualified` set to `false` will now have previous assignments loaded on `assign` regardless of whether or not the merchant no longer qualifies
* Here's the change in logic for `assign` based on whether or not the `store_unqualified` flag is on:

Old behaviour:

| store_unqualified                                                           | true | false |
|-----------------------------------------------------------------------------|------|-------|
| assignments for subjects that don't qualify are persisted in the database                   | yes  | no    |
| existing assignments are returned (even if subject doesn't qualify anymore) | yes  | no    |

New behaviour:

| store_unqualified                                                           | true | false |
|-----------------------------------------------------------------------------|------|-------|
| assignments for subjects that don't qualify are persisted in the database                   | yes  | no    |
| existing assignments are returned (even if subject doesn't qualify anymore) | yes  | **yes** |

## v0.7.0
**This version has breaking changes**

* Experiment can now specify multiple qualify blocks
  * `Verdict::Experiment#qualifier` has been removed in favor for `Verdict::Experiment#qualifiers`, which returns an array of procs
* Allow pass of an argument to qualify with a method name as a symbol, instead of a block

## v0.6.3

* Fix bug were Verdict.directory is overwritten
* Allow Verdict.directory to handle multiple directories (using globbing)

## v0.6.2

* Implement Verdict.clear_repository_cache, which fixes autoloading issues with Rails.
* Integrated Verdict.clear_repository_cache with our Railtie.

## v0.6.1

* Make Verdict Railtie `.freeze` the eager_load_paths it changes as Rails itself does.

## v0.6.0
**This version has breaking changes**

### Verdict::Experiment
* replaced following public methods that took a `subject_identifier` with an equivalent method which takes a `subject`

| old method                                                      | new method                               |
| --------------------------------------------------------------- | ---------------------------------------- |
| `lookup_assignment_for_identifier(subject_identifier)`          | `lookup(subject)`                        |
| `assign_manually_by_identifier(subject_identifier, group)`      | `assign_manually(subject, group)`        |
| `disqualify_manually_by_identifier(subject_identifier)`         | `disqualify_manually(subject)`           |
| `remove_subject_assignment_by_identifier(subject_identifier)`   | `remove_subject_assignment(subject)`     |
| `fetch_assignment(subject_identifier)`                          | `lookup(subject)`                        |

* Changed the following methods to take a `subject` instead of `subject_identifier`
 * `subject_assignment(subject, group, originally_created_at = nil, temporary = false)`
 * `subject_conversion(subject, goal, created_at = Time.now.utc)`

#### Improved Testability
`Verdict::Experiment#subject_qualifies?(subject, context = nil)` is now public, so it's easier to test
the qualification logic for your experiments.

### Verdict::BaseStorage
* `BaseStorage`'s public methods now take a `subject`, instead of a `subject_identifier`. They fetch the `subject_identifier` using the `Experiment#subject_identifier(subject)` method. Existing storages **will still work normally**.
* The basic `#get`,`#set`, and `#remove` methods are now protected.

### Verdict::Assignment
* `#initialize` now takes a `subject` instead of a `subject_identifier`, the new signature is `initialize(experiment, subject, group, originally_created_at, temporary = false)`

### Verdict::Conversion
* `#initialize` now takes a `subject` instead of a `subject_identifier`, the new signature is `initialize(experiment, subject, goal, created_at = Time.now.utc)`

### Rake Tasks
* In order to use the included helper Rake Tasks, you must implement `fetch_subject(subject_identifier)` in `Experiment`.

### Unsupported Ruby Versions
Support has been removed for the following Ruby versions:
- 1.9.X
- Rubinius
