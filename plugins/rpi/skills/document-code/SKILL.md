---
description: "The canon for comments and docstrings — what earns a place in a file, and the failure modes that recur. Use before writing any comment, in any language or file type, including one you are about to add mid-implementation; when finished code carries no docs; when asked to document something or add YARD; when auditing comments already in a file; and when a review says a comment restates the code, narrates your reasoning, or should be deleted rather than shortened."
---

You are writing the contract the next reader needs — a comment, a docstring, a YARD block. The rule is the same in Ruby, in YAML, in a Dockerfile, in a shell script, and those are where it gets forgotten. You are not recording the work you just did: the diff, the commit message and the PR already hold that.

The pass runs in both directions: adding what a file lacks, and taking out what it should never have carried. The second is the harder one, because the material reads as helpful.

## The tell

The urge fires hardest right after you have worked something out — a gem's retry behaviour, an ordering constraint, why one branch had to come first. The discovery feels too expensive to leave unwritten. That feeling is the signal to stop, not the licence to write: what was expensive to learn is not thereby worth recording at the call site.

Underneath it sits a simpler motive. Code does not show effort — it works or it does not. A comment does. A sentence that exists so a reviewer can see that its author understood the system is a performance, and it is addressed to the wrong reader.

Cutting them once does not inoculate. Removed at one layer, the same instinct surfaces at the next: delete the defensive default and it wants to become a docstring caveat; delete the caveat and it wants to become a test for the impossible case; delete that and it wants to become a paragraph in the pull request.

## Documenting is its own pass

It starts when the code works, and not before. A comment written while the code is being written is written by someone still deciding, so what it captures is the deciding. The cheapest way to keep that out of the file is to write no comments during the work at all — then there is nothing to judge afterwards, only something to add.

## The canon

Rails is the reference — read it, do not reconstruct it from memory.

### The shape

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

### Where volume belongs

`ActiveRecord::Transactions` carries some 190 lines of prose, and all of it sits above `module ClassMethods` — the public entry point. It answers one question: what will surprise you when you use this. Nested transactions commit both records; a rescued `StatementInvalid` poisons a PostgreSQL transaction; MySQL releases savepoints on DDL. Each is demonstrated by a runnable block, and the PostgreSQL section prints the real error text.

In that same file `restore_transaction_record_state` — thirty lines of branching over composite primary keys — carries one line, and `def destroy # :nodoc:` carries none: internal, no contract, nothing to say. The hardest method in the file has the shortest comment.

Long is allowed at the public boundary, about the caller's surprises, with examples. A long comment over a private method is that canon upside down.

### Which layer you document

Rails documents MySQL and PostgreSQL, because Rails is the abstraction over them and their behaviour leaks through its own interface. It never documents Ruby. In your application Rails is that lower layer and it has documented itself, so a comment explaining what `includes` buys, or how a gem retries, is noise — and it dates your file to the version you wrote it against.

Document downward, into what you hide. Never sideways, into a class that has a file of its own.

### What never appears

No ticket ids, no phases, no version history, no alternatives considered, and no provenance — where a pattern came from, which review caught it, what you verified before committing. Where a real decision exists, Rails states it as a present-tense fact and links the vendor's own manual: "Most databases don't support true nested transactions... Active Record emulates nested transactions by using savepoints." Never "we chose savepoints because".

## What survives

Delete the comment and read the code without it. If nothing is lost, it was restating — leave it deleted.

Then ask whether the fact can be shown: as input and output, or as an outcome someone could observe. `# => "foo bar boo"` can be run. "Without this guard, a second worker would charge the account twice" cannot — it describes a world that does not exist, which makes it an argument, and arguments belong in the pull request.

What survives carries something the code cannot: a decision that binds, a constraint, a measured fact.

Types are **declared** in `@param` and `@return`, never described beside them. A duck type says more than a class name — `[String, #read]` states what the method actually needs.

## Where no comment belongs

**Tests.** Not a header block, not a note above a case, not a preamble explaining why the case exists. The test name states the behaviour, helper names state the mechanism, and the assertion message carries what a fixer needs. If the behaviour is not legible from the name, the name is wrong — rename it. A test that seems to need a comment is asking for a named helper.

**Config and migrations.** YAML workflows, JSON config, `.env` templates: the setting name and its value are the contract. Whoever needs to know why a value is what it is reads git blame, then the commit message. Migrations run once.

## Auditing what a file already carries

Read the diff, each comment beside its code. Never grep for comment lines: the delete test cannot be run on a list with no code in it, and what that produces is rewriting by feel — polishing comments that should have been deleted, and keeping one that was factually wrong about the line beneath it.

When a comment contradicts the code, the first question is whether to delete it, not how to reword it. Stale narration rewritten is still narration, merely true again today.

A comments-only change runs nothing. Do not re-run the suite to verify it.

---

## Anti-patterns

### Reasoning narrated in a YARD block

The comment explains why the author reached for something, instead of what a reader must not break.

```ruby
# ✗
# Read in a transaction so it reaches the writer. A caller writes the row it is
# about to summarise and summarises immediately afterwards; served by a replica
# that has not caught up, the summary would omit the very row it exists to
# report, and would still be persisted.
#
# @return [Array<Hash>] rows, oldest first
def call
```

```ruby
# ✓ the constraint, and where it is written down
# Read in a transaction so it reaches the writer rather than a replica that
# has not caught up — see doc/read-after-write.md.
#
# @return [Array<Hash>] rows, oldest first
def call
```

### Restating the line below it

```ruby
# ✗
# What state an order is in decides what it may become next, and lets a refund
# close a payment while it is still pending.
enum :state, {pending: 0, paid: 1, refunded: 2}, prefix: :state
```

```ruby
# ✓
enum :state, {pending: 0, paid: 1, refunded: 2}, prefix: :state
```

The enum says which states exist. Nothing else was known.

### Prose repeating the tag it sits on

```ruby
# ✗
# @return [String] the text shown to the customer
def display_name
```

```ruby
# ✓
# @return [String]
def display_name
```

Delete the sentence, keep the tag. The sentence was the method name again.

### Shortening when the answer is deletion

The failure has three steps, and the third is the only correct one.

```ruby
# ✗ as written
# The whole account is read at once because every order of it travels in the
# response; the line items ride along preloaded, so pairing a charge to its
# refund costs no further query.

# ✗ told it was noise, made it shorter — same comment, fewer words
# Read whole because every order travels in the response, with the line items
# preloaded so pairing a charge to its refund costs no further query.

# ✓ what `includes` buys is Rails knowledge; the rest the code says
```

A reviewer saying a comment should not exist is asking for `delete`. A tighter version comes back in the next review.

### History, phases and roads not taken

```ruby
# ✗
# Phase 2 of PROJ-412. Originally this used a JSON column on the order, but
# that made settled? a document dig, so we moved to rows instead.
class LineItem < ApplicationRecord
```

```ruby
# ✓
# One line of an order.
#
# Amounts the system writes itself — a currency conversion, later a retried
# gateway fee — enter as their own line marked `system_origin`, never merged
# into a customer line: a charge the customer did not agree to must not come
# back to them as one they made.
class LineItem < ApplicationRecord
```

The good one states an invariant a reader would otherwise break, and reads the same in a year to someone who never knew a JSON column was considered. Ticket ids, phases and rejected alternatives go in the commit message.

---

## The one comment that belongs in the body

A measured constraint on the implementation, sitting at the line it constrains. `blank?` again:

```ruby
def blank?
  # The regexp that matches blank strings is expensive. For the case of empty
  # strings we can speed up this method (~3.5x) with an empty? call. The
  # penalty for the rest of strings is marginal.
  empty? || ...
```

The contract goes above the method; this goes inside it, and only when someone would otherwise simplify the line and lose the property.
