---
name: openqa-coding-practices
description: |
  Coding practices for os-autoinst and openQA related repositories.
triggers:
  - os-autoinst
  - os-autoinst-common
  - openQA
---

# openQA coding practices
Follow these coding practices when writing code for openQA-related repositories.

## General
* Avoid repetitions.
* Keep functions short.
* Do NOT silently ignore errors. Always handle errors appropriately.
* Comments and commit messages:
    * Focus on the *why* (and NOT on the *what*). (You may describe the *what*
      if it is not obvious or counterintuitive, though.)
    * Avoid overuse of comments; avoid long commit messages; do NOT describe the
      obvious.
    * Write comments like `# do this` and `# do that`.
    * Do NOT include numbers (so do NOT write comments like `# 1. do this`).
    * Use sub tests instead of comments when writing test where appropriate.
    * Include a line `Related ticket: https://progress.opensuse.org/issues/…` at
      the end of commit messages (if a ticket is known in the current context).

## Perl
* Prefer using abstractions from Mojolicious like `Mojo::File` and `Mojo::Util`
  if appropriate.
    * Use `scope_guard` from `Mojo::Util` for reliable resource cleanup.
    * Use database transactions in tests if cleanup after a sub test is
      necessary. (This may not always be possible, though.)
* Use e.g. `Time::Seconds` instead of hard-coding multipliers for data values.

## JavaScript
* Use plain DOM APIs. Avoid using jQuery.
* Use optional chaining instead of manual conditions where it makes sense **if**
  an object is expected to be undefined.
* Use template literals/strings instead of chaining `+` operations.
