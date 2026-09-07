---
description: "The canon for comments and docstrings — which mode the code is in, which of the four types a comment is, and the failure modes that recur. Use before writing any comment, in any language or file type, including one you are about to add mid-implementation; when finished code carries no docs; when asked to document something or add YARD; when auditing comments already in a file; and when a review says a comment restates the code, narrates your reasoning, or should be deleted rather than shortened."
---

In a high-level language a comment does not describe what the code does. Ruby reads as English; anything a comment says about behaviour, the lines below it say better and stay true longer. What is left for a comment is what the code cannot say about itself — a short list, worth knowing by name.

You are writing the contract the next reader needs — a comment, a docstring, a YARD block. The rule is the same in Ruby, in YAML, in a Dockerfile, in a shell script, and those are where it gets forgotten. You are not recording the work you just did: the diff, the commit message and the PR already hold that.

## Documenting is its own pass

It starts when the code works, and not before. A comment written while the code is being written is written by someone still deciding, so what it captures is the deciding. The cheapest way to keep that out of the file is to write no comments during the work at all — then there is nothing to judge afterwards, only something to add.

## Which mode you are in

Decide this once for the unit, before any of what follows. The question is not whether the repository is public. It is whether there is a consumer who is expected **not** to read the source.

**Library.** A gem, an npm package, an extracted engine — and equally an internal package another team consumes. The reader is in generated docs, in an IDE hover, in `ri`: the source is hidden by choice. Here the comment *is* the interface.

**Application.** `app/`, `lib/` of a service, anything a teammate or an agent reads by opening it. The source is the interface. Nobody generates docs over it, and whoever wants to know what a service does opens the service. A comment restating behaviour has no reader in this mode.

**Neither.** Tests, config, migrations carry no prose at all. Machine-facing markers stay.

Rails settles this inside one file. `ActiveRecord::Transactions` carries some 190 lines above `module ClassMethods`, its public entry point — and `def destroy # :nodoc:` carries none, while `restore_transaction_record_state`, thirty lines of branching over composite primary keys, carries one. `:nodoc:` marks "no contract here". **An application lives entirely in the `:nodoc:` half.**

Two boundaries worth naming, because they are guessed wrong:

- An internal package with another team as its consumer is in library mode, private repository or not. The boundary is "reading the implementation is not expected", not publication.
- A service wrapping a vendor's API is a library *with respect to that vendor* — it documents what leaks through from below — and an application everywhere else.

## The four types

Every comment that survives is one of these. **If you cannot name the type, do not write it** — that is the whole of the anti-pattern list below, stated once.

### Contract — for a caller who will not read the source

How to use it, what will surprise you, what you must not do, what it will never do. `ActiveSupport`'s `blank?`:

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

The surprises belong here too, not in a section of their own: a nested transaction commits both records; a rescued `StatementInvalid` poisons a PostgreSQL transaction; MySQL releases savepoints on DDL. So does the limit — "fully distributed transactions are beyond the scope of Active Record" — so a reader stops looking here for it.

### Identity — what this is in the domain

One or two lines, on the class or module, and only when the name does not carry it. The code shows mechanism; the concept's place in the business is not recoverable by reading.

```ruby
# A price as the customer sees it, in the currency they were quoted in.
class DisplayPrice
```

### Constraint — for whoever edits this line next

What breaks if it changes, and where that is written down. Three shapes:

*A measured property*, at the line it constrains, where the obvious simplification would silently lose it:

```ruby
def blank?
  # The regexp that matches blank strings is expensive. For the case of empty
  # strings we can speed up this method (~3.5x) with an empty? call. The
  # penalty for the rest of strings is marginal.
  empty? || ...
```

*An invariant whose violation is silent* — amounts the system writes never merge into a customer's line; ids go to the log, never the raw parameter. The silence is the criterion: **if breaking the rule fails a test, the test is the documentation** and no comment is needed. What earns one is the breakage nothing catches — a leaked log line, a cross-tenant read, two renders sharing a cache key.

*A fact that lives outside this file* — a provider's hard limit, a schema quirk, a coupling invisible at the call site — carrying a pointer to where it is recorded: `see doc/read-after-write.md`.

### Declaration — for tooling and the reader's eye

Types and markers, not prose. `@param` and `@return` **declare**; they are never described beside. A duck type says more than a class name — `[String, #read]` states what the method actually needs. `# :nodoc:`, `# frozen_string_literal: true` and linter directives are the rest of this type.

## Where each type applies

| Type | Library | Application | Tests, config, migrations |
| --- | --- | --- | --- |
| **Contract** | required at every public entry point | rare — only where a consumer really is kept from the source | — |
| **Identity** | on the public classes | on the class, when the name does not carry the domain role | — |
| **Constraint** | as the occasion arises | the main type; in an application it is most of what remains | — |
| **Declaration** | yes | yes | markers only |

The inversion is the point of the distinction: in a library Contract is the default and Constraint the occasion; in an application it is the other way round.

Before any type at all, **try the name first.** If a better method name, a better parameter name, or an extracted named helper removes the question, that is the fix. A comment is what remains when naming cannot carry it.

## The shape it takes

Rails is the reference — read it, do not reconstruct it from memory.

A statement of what the thing **is**, in the present tense, facing the caller. Then examples carrying input and output. Then the type tag — Rails writes `@return` even on a method whose name already answers it, because the tag is the signature and the sentence is not.

`String#squish` runs nine lines of comment over two lines of code, and each is either the statement or an example with its result beside it: `" foo   bar    \n   \t   boo".squish # => "foo bar boo"`. `String#truncate` scales the same shape — one statement, then an example per branch, down to the edge case where the omission is longer than the limit. `String#squish!` gets one line and a pointer to its sibling. `ActionController::Parameters#require` takes it under load: an example per branch, each way it raises included, with warnings riding inline (`# CAREFUL`, `# SAFER`).

Show input and output. Prose describing what an example would have shown is the thing to delete.

Long is allowed at the public boundary, about the caller's surprises, with examples. A long comment over a private method is that canon upside down.

## The two tests

Delete the comment and read the code without it. If nothing is lost, it was restating — leave it deleted.

Then ask whether the fact can be shown: as input and output, or as an outcome someone could observe. `# => "foo bar boo"` can be run. "Without this guard, a second worker would charge the account twice" cannot — it describes a world that does not exist, which makes it an argument, and arguments belong in the pull request.

---

## Anti-patterns

Each one below is the same failure: a comment whose type cannot be named. Narration is not a type. History is not a type. Justification is not a type.

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

Identity, then one constraint. It reads the same in a year to someone who never knew a JSON column was considered. Where a real decision exists, Rails states it as a present-tense fact and links the vendor's own manual — never "we chose savepoints because".

### In tests, config and migrations

**Tests.** Not a header block, not a note above a case, not a preamble explaining why the case exists. The test name states the behaviour, helper names state the mechanism, and the assertion message carries what a fixer needs. If the behaviour is not legible from the name, the name is wrong — rename it. A test that seems to need a comment is asking for a named helper.

**Config and migrations.** YAML workflows, JSON config, `.env` templates: the setting name and its value are the contract. Whoever needs to know why a value is what it is reads git blame, then the commit message. Migrations run once.

### Auditing what a file already carries

Read the diff, each comment beside its code. Never grep for comment lines: the delete test cannot be run on a list with no code in it, and what that produces is rewriting by feel — polishing comments that should have been deleted, and keeping one that was factually wrong about the line beneath it.

When a comment contradicts the code, the first question is whether to delete it, not how to reword it. Stale narration rewritten is still narration, merely true again today.

A comments-only change runs nothing. Do not re-run the suite to verify it.

## Anti-Patterns Quick List

| Anti-Pattern | Solution |
|--------------|----------|
| A comment whose type you cannot name | Delete it |
| Narrating what the next line does | Delete it — the language reads |
| A contract in application code | Delete it — the reader opens the file |
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
