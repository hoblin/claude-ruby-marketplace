---
description: "The canon for comments and docstrings — when one is warranted, what shape it takes, and the failure modes that recur. Use before writing any comment, in any language or file type, including one you are about to add mid-implementation; when finished code carries no docs; when asked to document something or add YARD; when auditing comments already in a file; and when a review says a comment restates the code, narrates your reasoning, or should be deleted rather than shortened."
---

In a high-level language a comment does not describe what the code does. Ruby reads as English; anything a comment says about behaviour, the lines below it say better and stay true longer. What is left for a comment is what the code cannot say about itself — and that is a short list, worth knowing by name.

You are writing the contract the next reader needs — a comment, a docstring, a YARD block. The rule is the same in Ruby, in YAML, in a Dockerfile, in a shell script, and those are where it gets forgotten. You are not recording the work you just did: the diff, the commit message and the PR already hold that.

## Documenting is its own pass

It starts when the code works, and not before. A comment written while the code is being written is written by someone still deciding, so what it captures is the deciding. The cheapest way to keep that out of the file is to write no comments during the work at all — then there is nothing to judge afterwards, only something to add.

## When a comment is warranted

Before any of the eight: **try the name first.** If a better method name, a better parameter name, or an extracted named helper removes the question, that is the fix. A comment is what remains when naming cannot carry it.

Case 1 applies by default, to everything public. The other seven apply on occasion — when the occasion actually arises, not in case it might.

### The contract — facing the caller

**1. A public method, class or module.** Without it there is no abstraction: to use the thing, a caller has to read its body. What it is, in the present tense, with examples carrying input and output.
*Test: can a caller use this without opening the implementation?*

**2. Behaviour that contradicts a reasonable expectation.** Not complex — surprising. A nested transaction commits both records; `after_save` runs before the commit lands. Shown with a runnable example.
*Test: would a competent reader, reasoning by analogy, get this wrong?*

**3. A warning: what must not be done.** `ActiveRecord::Transactions` spends a section on rescuing `StatementInvalid` inside a transaction block, and another on DDL inside an emulated savepoint. Case 2 says you will be surprised; case 3 says you will break it.
*Test: is there an action that looks legitimate and is not?*

**4. The boundary of what this will never do.** "Fully distributed transactions are beyond the scope of Active Record" — so the reader stops looking here for it.
*Test: will a reader search this thing for something it does not have?*

**5. A leak of the layer you hide.** Rails documents MySQL and PostgreSQL, because it is the abstraction over them and their behaviour shows through its own interface. It never documents Ruby. In your application Rails is that lower layer and has documented itself.
*Test: is this the layer you hide, or one that documents itself?*

### The constraint — facing the editor

**6. A measured property of one line.** It sits at the line it constrains, inside the method, and only where the obvious simplification would silently lose it:

```ruby
def blank?
  # The regexp that matches blank strings is expensive. For the case of empty
  # strings we can speed up this method (~3.5x) with an empty? call. The
  # penalty for the rest of strings is marginal.
  empty? || ...
```

*Test: is there a number, and would a tidy-up throw it away?*

**7. An invariant whose violation is silent.** A rule binding future edits: amounts the system writes never merge into a customer's line; ids go to the log, never the raw parameter. The criterion is the silence — **if breaking the rule fails a test, the test is the documentation** and no comment is needed. A comment earns its place where nothing fails: a leaked log line, a cross-tenant read, two renders sharing one cache key.
*Test: would breaking this be caught by anything? If yes, write nothing.*

**8. A fact that lives outside this file.** A provider's hard limit, a schema quirk, a coupling invisible at the call site — with a pointer to where it is written down (`see doc/read-after-write.md`).
*Test: would you have to open another file, or someone else's documentation, to learn this?*

## The form a warranted comment takes

Rails is the reference — read it, do not reconstruct it from memory.

`ActiveSupport`'s `blank?`:

```ruby
# An object is blank if it's false, empty, or a whitespace string.
# For example, +nil+, '', '   ', [], {}, and +false+ are all blank.
#
# This simplifies
#
#   !address || address.empty?
#
# to
#
#   address.blank?
#
# @return [true, false]
def blank?
  respond_to?(:empty?) ? !!empty? : !self
end
```

A statement of what the thing **is**, in the present tense, facing the caller. Then examples carrying input and output. Then the type tag — Rails writes `@return` even on a method whose name already answers it, because the tag is the signature and the sentence is not.

`String#squish` runs nine lines of comment over two lines of code, and each is either the statement or an example with its result beside it: `" foo   bar    \n   \t   boo".squish # => "foo bar boo"`. `String#truncate` scales the same shape — one statement, then an example per branch, down to the edge case where the omission is longer than the limit. `String#squish!` gets one line and a pointer to its sibling. `ActionController::Parameters#require` takes it under load: an example per branch, each way it raises included, with warnings riding inline (`# CAREFUL`, `# SAFER`).

Show input and output. Prose describing what an example would have shown is the thing to delete.

Types are **declared** in `@param` and `@return`, never described beside them. A duck type says more than a class name — `[String, #read]` states what the method actually needs.

### Where volume belongs

`ActiveRecord::Transactions` carries some 190 lines of prose, and all of it sits above `module ClassMethods` — the public entry point. In that same file `restore_transaction_record_state` — thirty lines of branching over composite primary keys — carries one line, and `def destroy # :nodoc:` carries none: internal, no contract, nothing to say. The hardest method in the file has the shortest comment.

Long is allowed at the public boundary, about the caller's surprises, with examples. A long comment over a private method is that canon upside down.

## The two tests

Delete the comment and read the code without it. If nothing is lost, it was restating — leave it deleted.

Then ask whether the fact can be shown: as input and output, or as an outcome someone could observe. `# => "foo bar boo"` can be run. "Without this guard, a second worker would charge the account twice" cannot — it describes a world that does not exist, which makes it an argument, and arguments belong in the pull request.

---

## Anti-patterns

### The tell

The urge fires hardest right after you have worked something out — a gem's retry behaviour, an ordering constraint, why one branch had to come first. The discovery feels too expensive to leave unwritten. That feeling is the signal to stop, not the licence to write: what was expensive to learn is not thereby worth recording at the call site.

Underneath it sits a simpler motive. Code does not show effort — it works or it does not. A comment does. A sentence that exists so a reviewer can see that its author understood the system is a performance, and it is addressed to the wrong reader.

Cutting them once does not inoculate. Removed at one layer, the same instinct surfaces at the next: delete the defensive default and it wants to become a docstring caveat; delete the caveat and it wants to become a test for the impossible case; delete that and it wants to become a paragraph in the pull request.

### Where the habit was learned

Public code is mostly written for a stranger who lacks the context, not for a colleague who will maintain it. Each genre has a reader production does not have, and each teaches a register that is wrong here:

| Genre | Its reader | What it teaches |
| --- | --- | --- |
| Tutorials, README samples, Stack Overflow | someone learning the language | narrate the next line |
| Take-home tests, coursework | a grader | prove the author understood |
| Notebooks | the author, thinking | reason out loud in the file |
| Review threads | an opponent | argue the choice |
| Legacy file headers | a team without version control | record who changed what, when |
| Config templates | a newcomer configuring | annotate every setting |

The corpus also holds only the comments that were written. One a reviewer had removed leaves no public trace, so writing has millions of examples behind it and deleting has almost none.

```ruby
# BAD - the tutorial register: the reader is learning Ruby
# Loop through the orders and add up their totals
orders.sum(&:total)

# BAD - the take-home register: the reader is grading
# sum rather than inject, for readability; O(n) either way
orders.sum(&:total)

# GOOD - the line says it, and the reader is a colleague
orders.sum(&:total)
```

### Reasoning narrated in a YARD block

The comment explains why the author reached for something, instead of what a reader must not break.

```ruby
# BAD
# Read in a transaction so it reaches the writer. A caller writes the row it is
# about to summarise and summarises immediately afterwards; served by a replica
# that has not caught up, the summary would omit the very row it exists to
# report, and would still be persisted.
#
# @return [Array<Hash>] rows, oldest first
def call
```

```ruby
# GOOD - the constraint, and where it is written down
# Read in a transaction so it reaches the writer rather than a replica that
# has not caught up — see doc/read-after-write.md.
#
# @return [Array<Hash>] rows, oldest first
def call
```

### Restating the line below it

```ruby
# BAD
# What state an order is in decides what it may become next, and lets a refund
# close a payment while it is still pending.
enum :state, {pending: 0, paid: 1, refunded: 2}, prefix: :state
```

```ruby
# GOOD
enum :state, {pending: 0, paid: 1, refunded: 2}, prefix: :state
```

The enum says which states exist. Nothing else was known.

### Prose repeating the tag it sits on

```ruby
# BAD
# @return [String] the text shown to the customer
def display_name
```

```ruby
# GOOD
# @return [String]
def display_name
```

Delete the sentence, keep the tag. The sentence was the method name again.

### Shortening when the answer is deletion

The failure has three steps, and the third is the only correct one.

```ruby
# BAD - as written
# The whole account is read at once because every order of it travels in the
# response; the line items ride along preloaded, so pairing a charge to its
# refund costs no further query.

# BAD - told it was noise, made it shorter: same comment, fewer words
# Read whole because every order travels in the response, with the line items
# preloaded so pairing a charge to its refund costs no further query.

# GOOD - what `includes` buys is Rails knowledge; the rest the code says
```

A reviewer saying a comment should not exist is asking for `delete`. A tighter version comes back in the next review.

### History, phases and roads not taken

```ruby
# BAD
# Phase 2 of PROJ-412. Originally this used a JSON column on the order, but
# that made settled? a document dig, so we moved to rows instead.
class LineItem < ApplicationRecord
```

```ruby
# GOOD
# One line of an order.
#
# Amounts the system writes itself — a currency conversion, later a retried
# gateway fee — enter as their own line marked `system_origin`, never merged
# into a customer line: a charge the customer did not agree to must not come
# back to them as one they made.
class LineItem < ApplicationRecord
```

The good one states an invariant a reader would otherwise break, and reads the same in a year to someone who never knew a JSON column was considered. Where a real decision exists, Rails states it as a present-tense fact and links the vendor's own manual — never "we chose savepoints because".

### Where no comment belongs at all

**Tests.** Not a header block, not a note above a case, not a preamble explaining why the case exists. The test name states the behaviour, helper names state the mechanism, and the assertion message carries what a fixer needs. If the behaviour is not legible from the name, the name is wrong — rename it. A test that seems to need a comment is asking for a named helper.

**Config and migrations.** YAML workflows, JSON config, `.env` templates: the setting name and its value are the contract. Whoever needs to know why a value is what it is reads git blame, then the commit message. Migrations run once.

### Auditing what a file already carries

Read the diff, each comment beside its code. Never grep for comment lines: the delete test cannot be run on a list with no code in it, and what that produces is rewriting by feel — polishing comments that should have been deleted, and keeping one that was factually wrong about the line beneath it.

When a comment contradicts the code, the first question is whether to delete it, not how to reword it. Stale narration rewritten is still narration, merely true again today.

A comments-only change runs nothing. Do not re-run the suite to verify it.

## Anti-Patterns Quick List

| Anti-Pattern | Solution |
|--------------|----------|
| Narrating what the next line does | Delete it — the language reads |
| Reasoning narrated in a docstring | State the constraint a reader must not break; the reasoning goes in the PR |
| Prose repeating the tag it sits on | Delete the sentence, keep the tag |
| Shortening a comment a reviewer called noise | Delete it — a tighter version comes back next review |
| Ticket ids, phases, alternatives, provenance | Commit message |
| A long comment over a private method | Volume belongs at the public boundary |
| Explaining what Rails or a gem does | Delete it — that layer documents itself |
| A counterfactual: "would otherwise…" | It is an argument; arguments go in the PR body |
| A rule a test already enforces | Delete it — the test is the documentation |
| A comment in a test | Rename the test, or extract a named helper |
| A comment in config or a migration | Delete it — the setting name is the contract |
| A comment that contradicts its code | Delete first; reword only if the fact still binds |
| A question a better name would answer | Rename, then see whether anything is left to say |
| Auditing by grepping comment lines | Read the diff, each comment beside its code |
