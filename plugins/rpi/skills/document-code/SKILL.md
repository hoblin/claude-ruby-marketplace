---
description: "Decide whether a comment belongs, and write the ones that do — in Ruby, YAML, a Dockerfile, a shell script, tests or config. Use it before adding any comment, docstring or YARD block, including one you are about to write mid-implementation, and before deleting or rewording one already there. Use it when finished code carries no documentation, when asked to document code or add YARD, and when auditing what a file or a diff already carries. Use it unprompted when a review says a comment restates the code, narrates reasoning, is outdated, or should be deleted rather than shortened. Not for prose documents — a README, a wiki page, a plan or a ticket."
---

A comment is never read on its own. It reaches its reader attached to the lines beneath it, and those lines are already in front of that reader. So every judgement in this skill — whether a comment is needed, what it should say, whether it should go — is a judgement about the pair, and a comment read apart from its code cannot be judged at all.

## Modes

What a comment is for depends on who reads the code it sits in. Settle that first, before writing anything.

**Step one: `Mode: <name>` is your first output, ahead of any tool call.** Print it again for each part of the codebase that falls in a different mode.

People make this choice without noticing they have made it. A script written to run once and be forgotten gets no comments at all; a library other teams depend on gets a full contract. Same author, same language — what differs is how long the code will live and who will have to read it. An agent has no such instinct: left to itself it copies whatever register the surrounding text happens to use. Naming the mode out loud replaces the instinct.

The question to answer is not whether the repository is public. It is who reads this code, and whether they are expected to read the source at all.

**application** (the default) — `app/`, a service's `lib/`. Read by a teammate or an agent who opens the file, so a comment carries only what reading the code cannot give.

**library** — a gem, an engine, a package another team consumes. Read in generated documentation, an IDE hover or `ri`, so a comment stands in for source the reader will not open.

**tests, config, migrations** — read by whoever edits them, with the code beside. No prose; machine-readable markers stay.

**teaching** — a tutorial, a README sample, a demo. Read by someone learning the language, so narrating each line is the point.

**assessed** — a take-home, coursework. Read by a grader, so showing the author's reasoning is the deliverable.

**throwaway** — a script that runs once. Read by nobody, including its author next month. Nothing.

Each of those registers is correct in its own mode. A tutorial that narrates every line is doing its job, and so is a take-home exercise that shows the candidate thinking. Every anti-pattern in this skill is one of those registers written into a mode it does not belong to — most often a teaching or an assessed register written into an application.

Two cases that get judged wrongly:

- An internal package that another team consumes is in **library** mode even though its repository is private. What makes it a library is that its consumers are not expected to read its implementation.
- A service that wraps a vendor's API is a library with respect to that vendor: it documents the vendor behaviour that leaks through its own interface. Everywhere else that service is an application.

Rails draws this boundary inside a single file. In `ActiveRecord::Transactions`, some 190 lines of documentation sit above `module ClassMethods`, the public entry point callers reach for. In the same file `def destroy # :nodoc:`, an internal override, carries no documentation at all, and `restore_transaction_record_state`, thirty lines of branching over composite primary keys, carries a single line. The `# :nodoc:` marker means "no contract here, keep this out of the published docs". **Application code lives entirely on the `:nodoc:` side of that split.**

Everything below applies to **application** and **library** mode, and mostly to application.

## Why a comment is needed at all

In a high-level language a comment does not describe what the code does. Ruby reads close to English, so a sentence about behaviour is a worse copy of the lines beneath it, and it goes stale the moment they change. What is left for a comment is what the code cannot state about itself. That set is small: four types, named below.

A comment is also not a record of the work that produced the code. The diff shows what changed, the commit message says why, and the pull request holds the argument.

## Documenting is its own pass

Documentation starts once the code works, and not before. A comment written mid-implementation is written by someone who is still deciding, so what it captures is the deciding rather than the decision. The cheapest way to keep that out of the file is to write no comments during implementation at all: then the pass that follows has nothing to judge and only something to add.

## The four types

Every comment worth keeping is one of the four below. **If you cannot name which type a comment is, do not write it.** Every anti-pattern later in this skill is an instance of that one rule.

### Contract — for a caller who will not read the source

States how to use the thing, what about it will surprise a caller, what a caller must not do, and what it will never do. `ActiveSupport`'s `blank?`:

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

Surprises belong in the contract rather than in a comment of their own. `ActiveRecord::Transactions` documents three of its own: a rollback raised inside a nested transaction still commits both records; a `StatementInvalid` rescued inside a transaction block leaves a PostgreSQL transaction unusable; MySQL releases savepoints when a DDL statement runs. A limit belongs there too, so that a caller stops hunting for something that does not exist — that same file states plainly that fully distributed transactions are outside Active Record's scope.

### Identity — what this thing is in the domain

One or two lines on a class or module, written only when its name does not already carry the answer. Reading the code shows the mechanism; what the class represents in the business is not recoverable that way.

```ruby
# A price as the customer sees it, in the currency they were quoted in.
class DisplayPrice
```

### Constraint — for whoever edits this line next

States what breaks if the line changes, and where that is written down. It takes three shapes.

**A measured property**, placed at the line it constrains, and only where an obvious simplification would silently lose it. `blank?` again, this time inside the method body:

```ruby
def blank?
  # The regexp that matches blank strings is expensive. For the case of empty
  # strings we can speed up this method (~3.5x) with an empty? call. The
  # penalty for the rest of strings is marginal.
  empty? || ...
```

**An invariant whose violation is silent.** A rule that binds future edits: in a billing model, that amounts the system generates stay on their own row instead of merging into a customer's; in a logger, that record ids may be written but never the raw request parameter they came from. Silence is what qualifies it — **if breaking the rule makes a test fail, that test is the documentation** and no comment is needed. A comment earns its place where nothing catches the breakage: a leaked log line, one tenant reading another's data, two different renders sharing a cache key.

**A fact that lives outside this file** — a provider's hard limit, a quirk of the database schema, a coupling that is invisible at the call site. It carries a pointer to wherever the fact is recorded in full, for example `see doc/read-after-write.md`.

### Declaration — for tooling and for the reader's eye

Types and markers, never prose. `@param` and `@return` **declare** a type; they are not accompanied by a sentence describing it. A duck type says more than a class name: `[String, #read]` states what the method actually requires of its argument. Markers such as `# :nodoc:`, `# frozen_string_literal: true` and linter directives are the rest of this type.

## Where each type applies

**Contract** — required at every public entry point in library mode; rare in application code, where it belongs only if some consumer really is kept from the source.

**Identity** — on the public classes in library mode; in application code, on a class whose name does not carry its domain role.

**Constraint** — the routine case in application code, and most of what it needs; in library mode, as the occasion arises.

**Declaration** — in both modes.

In tests, config and migrations none of the four applies, markers aside.

Which type is routine and which is exceptional swaps between the two modes: application code writes Constraint by default and Contract rarely, a library the other way round. The three remaining modes — teaching, assessed and throwaway — do not use this table, because their readers set a register of their own.

Before reaching for any type, **try the name first.** If a better method name, a better parameter name, or a helper extracted and named after what it does removes the question, that is the fix. A comment is what remains when naming cannot carry the meaning.

## The shape a comment takes

Rails is the reference here. Read it rather than reconstructing it from memory.

The shape is: a statement of what the thing **is**, in the present tense, addressed to a caller; then examples that carry both input and output; then the type tag. Rails writes `@return` even on a method whose name already answers it, because the tag is the signature and a sentence is not.

`String#squish` carries nine lines of comment over two lines of code, and every one of those lines is either that opening statement or an example with its result written beside it, as in `" foo   bar    \n   \t   boo".squish # => "foo bar boo"`. `String#truncate` scales the same shape up: one statement, then an example per branch, down to the edge case where the omission string is longer than the limit. `String#squish!`, which does the same job in place, gets one line and a pointer to `String#squish`. `ActionController::Parameters#require` holds the shape under load, with an example per branch, each way the method raises included, and warnings riding inline as `# CAREFUL` and `# SAFER`.

Show input and output. A sentence describing what an example would have shown is the thing to delete.

Length is earned at a public entry point, spent on what will surprise a caller, and paid out in examples. The same length above a private method inverts that: whoever reads a private method can see the implementation, and is not being held to a contract.

## The two tests

First, delete the comment and read the code without it. If nothing was lost, the comment was restating the code — leave it deleted.

Second, ask whether what it says can be shown: as an input and an output, or as an outcome someone could observe. `# => "foo bar boo"` can be run and checked. A sentence such as "without this guard, a second worker would charge the account twice" cannot: it describes a world that does not exist, which makes it an argument for the code rather than a fact about it, and arguments belong in the pull request.

## Precedent is not a licence

A neighbouring comment that breaks these rules is not permission to write another like it — it is the next thing to clean. Leave what you touch cleaner than you found it. Where an older block of comments is the reason a new one took its shape, say so, because that older block is what keeps regenerating the pattern.

---

## Anti-patterns

Every anti-pattern below is one failure wearing different clothes: a comment whose type cannot be named. Narration is not a type. History is not a type. Justification is not a type.

### The urge, and where it comes from

The urge to write a comment fires hardest right after something has been worked out — how a gem retries, why one branch has to run before another, which ordering a constraint depends on. The discovery feels too expensive to leave unwritten. That feeling is a signal to stop rather than a licence to write: something being expensive to learn does not make it worth recording at the call site.

Underneath sits a simpler motive. Code does not show effort — it either works or it does not. A comment does show effort. A sentence written so that a reviewer can see its author understood the system is a performance for the reviewer, and the reviewer is not who reads the file next year.

Cutting such comments once does not inoculate against them. Removed from one place, the same instinct reappears in the next: delete a defensive default and it wants to become a caveat in a docstring; delete the caveat and it wants to become a test for a case that cannot happen; delete that test and it wants to become a paragraph in the pull request.

### Why the wrong register is the default

Public code is dominated by the modes that application code is not. Tutorials, Stack Overflow answers, coursework, notebooks, config templates and code-review threads are all written for a reader who lacks the context — a learner, a grader, an opponent. Application code written for a colleague who will maintain it is mostly private. So the register needed most often is the one with the fewest public examples.

Public code also contains only the comments that were written. A comment a reviewer had deleted leaves no trace anywhere public, so writing one has millions of examples behind it and deleting one has almost none.

```ruby
# BAD - the tutorial register: written for a reader learning Ruby
# Loop through the orders and add up their totals
orders.sum(&:total)

# BAD - the take-home register: written for a grader
# sum rather than inject, for readability; O(n) either way
orders.sum(&:total)

# GOOD - application register: the line says it, and the reader is a colleague
orders.sum(&:total)
```

### Reasoning narrated in a docstring

The comment explains why its author reached for something, in place of stating what a reader must not break.

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
# GOOD - the constraint, and where the reasoning is written down
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

The enum already lists every state an order can hold. What the deleted comment added — which transitions are legal — is enforced somewhere else in the model, and repeating it here creates a second copy that nothing keeps true.

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

Delete the sentence and keep the tag. The sentence was the method's own name written out again.

### Shortening when the answer is deletion

Three versions of one comment, over the same line of code. Only the third is right.

```ruby
# BAD - as written
# The whole account is loaded at once because every order travels in the
# response; the line items ride along preloaded, so pairing a charge to its
# refund costs no further query.
account.orders.includes(:line_items)

# BAD - told it was noise, made it shorter: the same comment, fewer words
# Loaded whole because every order travels in the response, with line items
# preloaded so pairing a charge to its refund costs no further query.
account.orders.includes(:line_items)

# GOOD - what `includes` does is Rails knowledge, and the call says the rest
account.orders.includes(:line_items)
```

A reviewer who says a comment should not exist is asking for it to be deleted. A shortened version of the same comment comes back at the next review.

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

The second version is Identity followed by one Constraint. It reads the same in a year to someone who never knew a JSON column had been considered. Where a genuine design decision has to be recorded, Rails states its outcome as a present-tense fact and links the vendor's own manual for the mechanism; it never writes out the deliberation that led there. Ticket ids, phases and rejected alternatives go in the commit message.

### In tests, config and migrations

**Tests.** No header block, no note above a case, no preamble explaining why a case exists. The test's name states the behaviour, helper names state the mechanism, and the assertion message carries what someone fixing a failure needs to know. If the behaviour is not legible from the name, the name is wrong and renaming it is the fix. A test that seems to need a comment is asking for a helper with a name.

**Config and migrations.** In YAML workflows, JSON config and `.env` templates, the setting's name and its value are the contract. Whoever needs to know why a value is what it is reads `git blame` and then the commit message. Migrations run once and are not read again.

### Auditing what a file already carries

Read the diff with each comment beside its code. Grepping for comment lines produces a list with no code in it, and the delete test cannot be run against such a list: what comes out instead is rewriting by feel — polishing comments that should have been deleted, and keeping one that was plainly wrong about the line beneath it.

When a comment contradicts the code it sits on, the first question is whether to delete it, not how to reword it. A stale narration rewritten is still narration, merely true again for today.

A change that touches only comments changes no behaviour, so it is verified by reading rather than by running the test suite.

## Anti-Patterns Quick List

A comment whose type you cannot name → delete it.
Narrating what the next line does → delete it; the language reads.
A contract in application code → delete it; the reader opens the file.
Reasoning narrated in a docstring → state the constraint a reader must not break, and put the reasoning in the pull request.
Prose repeating the tag it sits on → delete the sentence, keep the tag.
Shortening a comment a reviewer called noise → delete it; a shortened version comes back next review.
Ticket ids, phases, alternatives, provenance → commit message.
A long comment above a private method → length belongs at a public entry point.
Explaining what Rails or a gem does → delete it; that layer documents itself.
A counterfactual, "without this, X would…" → it is an argument, and arguments go in the pull request.
A rule a test already enforces → delete it; the test is the documentation.
A comment in a test → rename the test, or extract a named helper.
A comment in config or a migration → delete it; the setting name is the contract.
A comment that contradicts its code → delete first; reword only if the fact still binds.
A question a better name would answer → rename, then see whether anything is left to say.
Auditing by grepping comment lines → read the diff, each comment beside its code.
