# Verdict Concepts

Understanding the following Verdict concepts can help implement experiments and discuss them with peers.

- [Experiment](#experiment)
- [Qualifiers](#qualifiers)
- [Subject](#subject)
- [Group](#group)
- [Assignment](#assignment)

### Experiment

`Experiment`s are defined in `app/experiments` and encapsulate the details of the test including metadata such as the name, description or owners, as well as any [qualifiers](#qualifiers) or the [groups](#groups) available in the test.

### Qualifers

Qualifiers are methods that take two parameters, `subject` and `context` and returns `true` if the `subject` can take this experiment, or `false` if the `subject` is not eligible. Experiments can have multiple qualifiers which are evaluated in succession. If a qualifier returns `false` no further qualifiers are checked.

Examples of qualifiers might be:

- Include subjects that originate from SpeedCurve or WebPage Test
- Include subjects that have added items to their cart.

### Subject

A subject is the thing that will be [qualified](#qualifiers), and if successfull, [assigned](#assignment) to a particular [group](#group). For example, a subject might represent a user.

### Group

Each [experiment](#experiment) will have two or more groups, usually a control group and a test group. Qualified [subjects](#subject) are assigned to one of the groups in the experiment.

### Assignment

An assignment occurs when a qualified [subject](#subject) is placed into a [group](#group). Assignments are persisted so repeat visits by the subject skip [qualification](#qualifiers) and re-assignment and simply returns the existing assignment.
