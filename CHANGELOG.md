## v0.6.0
**This version has breaking changes**

### Verdict::Experiment
* replaced following public methods from `Experiment` that took a `subject_identifier` with an equivalent method which takes a `subject`

| old method                                                    | new method                             |
| ------------------------------------------------------------- | -------------------------------------- |
| lookup_assignment_for_identifier(subject_identifier)          | lookup(subject)                        |
| assign_manually_by_identifier(subject_identifier, group)      | assign_manually(subject, group)        |
| disqualify_manually_by_identifier(subject_identifier)         | disqualify_manually(subject)           |
| remove_subject_assignment_by_identifier(subject_identifier)   | remove_subject_assignment(subject)     |
| fetch_assignment(subject_identifier)                          | lookup(subject)                        |

* Changed the following methods in `Experiment` to take a `subject` instead of `subject_identifier`
 * subject_assignment(subject, group, originally_created_at = nil, temporary = false)
 * subject_conversion(subject, goal, created_at = Time.now.utc)

#### Improved Testability
`Verdict::Experiment#subject_qualifies?(subject, context = nil)` is now public, so it's easier to test
the qualification logic for your experiments.

### Verdict::BaseStorage
* `BaseStorage` now takes an instance of `subject` instead of `subject_identifier` and fetches the subject_identifier using the method in `Experiment`
* `BaseStorage` methods `get`,`set`, and`remove` made protected

### Verdict::Assignment
* `initialize` method now takes a `subject` instead of a `subject_identifier`, the new signature is `initialize(experiment, subject, group, originally_created_at, temporary = false)``

### Verdict::Conversion
* `initialize` method now takes a `subject` instead of a `subject_identifier`, the new signature is `initialize(experiment, subject, goal, created_at = Time.now.utc)`

### Rake Tasks
* In order to use the following Rake Tasks you must implement `fetch_subject(subject_identifier)` in `Experiment`
 * lookup_assignment(experiment, subject_identifier)
 * assign_manually(experiment, group, subject_identifier)
 * disqualify_manually(experiment, subject_identifier)
 * remove_assignment(experiment, subject_identifier)
