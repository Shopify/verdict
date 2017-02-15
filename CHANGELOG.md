## v0.6.0
**This version has breaking changes**

### Verdict::Experiment
* replaced following public methods from `Experiment` that took a `subject_identifier` with an equivalent method which takes a `subject`

| old method                                | new method                   |
| ----------------------------------------- | ---------------------------- |
| lookup_assignment_for_identifier          | lookup_assignment            |
| assign_manually_by_identifier             | assign_manually              |
| disqualify_manually_by_identifier         | disqualify_manually          |
| remove_subject_assignment_by_identifier   | remove_subject_assignment    |
| fetch_assignment                          | lookup                       |

* Changed the following methods in `Experiment` to take a `subject` instead of `subject_identifier`
 * subject_assignment
 * subject_conversion

#### Improved Testability
`Verdict::Experiment#subject_qualifies?(subject, context = nil)` is now public, so it's easier to test
the qualification logic for your experiments.

### Verdict::BaseStorage
* `BaseStorage` now takes an instance of `subject` instead of `subject_identifier` and fetches the subject_identifier using the method in `Experiment`
* `BaseStorage` methods `get`,`set`, and`remove` made protected

### Verdict::Assignment
* `initialize` method now takes a `subject` instead of a `subject_identifier`
* Assignment now stores a reference to `subject` instead of `subject_identifier`

### Verdict::Conversion
* `initialize` method now takes a `subject` instead of a `subject_identifier`
* Conversion now stores a reference to `subject` instead of `subject_identifier`

### Rake Tasks
* In order to use the following Rake Tasks you must implement `fetch_subject(subject_identifier)` in `Experiment`
 * lookup_assignment
 * assign_manually
 * disqualify_manually
 * remove_assignment
