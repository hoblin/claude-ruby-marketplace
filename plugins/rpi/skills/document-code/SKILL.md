---
description: "Decide whether a comment belongs, and write the ones that do — in Ruby, YAML, a Dockerfile, a shell script, tests or config. Use it before adding any comment, docstring or YARD block, including one you are about to write mid-implementation, and before deleting or rewording one already there. Use it when finished code carries no documentation, when asked to document code or add YARD, and when auditing what a file or a diff already carries. Use it unprompted when a review says a comment restates the code, narrates reasoning, is outdated, or should be deleted rather than shortened. Not for prose documents — a README, a wiki page, a plan or a ticket."
---

A comment is judged only together with the block of code it comments, never on its own. Whether it is needed, what it should say, and whether it should be deleted are decided by reading the two side by side.

## What you are documenting

**Step one: your first output names what you are about to document — `Published interface` or `Implementation`.** Say it again whenever you move to code of the other kind.

A **published interface** is code that other people call without reading it: a gem, an engine, a package another team consumes. Its comments are rendered by YARD, RDoc, an IDE hover or `ri`, away from the source, so they have to stand alone. Application code — `app/`, a service's `lib/` — has almost no published interface: whoever wants to know what a service does opens the service. Naming which one you are in decides everything that follows, and the answer is not "is the repository public": an internal package that another team consumes without reading it is a published interface, and a public repository nobody imports is not.

Two more situations exist and are not covered by this skill's rules, because their comments serve a different reader entirely. Code written to teach — a tutorial, a README sample — narrates each line on purpose; Knuth's literate programming is the extreme of it. Code written to be assessed, such as a take-home exercise, shows the author's reasoning because the reasoning is the deliverable. Neither register belongs in code that ships.

## The four kinds of comment

A comment that is none of these four has no reason to exist.

**Interface comment** — sits at the declaration of a class, module or method, and describes the abstraction: behaviour, arguments, return value, side effects, exceptions, what the caller must guarantee, and what the thing does not do. `Object#blank?`, from `active_support/core_ext/object/blank.rb`:

```ruby
class Object
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
    respond_to?(:empty?) ? !!empty? : false
  end
end
```

**Implementation comment** — describes how a piece of code works, or what constrains it. Almost always the wrong thing to write, because the code says how it works; the exception is a property of the implementation that the code cannot show and that an obvious simplification would silently destroy. `String#blank?`, from the same file:

```ruby
BLANK_RE = /\A[[:space:]]*\z/

class String
  def blank?
    # The regexp that matches blank strings is expensive. For the case of empty
    # strings we can speed up this method (~3.5x) with an empty? call. The
    # penalty for the rest of strings is marginal.
    empty? ||
      begin
        BLANK_RE.match?(self)
      rescue Encoding::CompatibilityError
        ENCODED_BLANKS[self.encoding].match?(self)
      end
  end
end
```

`BLANK_RE` matches an empty string as well, so `empty? ||` changes no result and reads as dead weight. Deleting it leaves every test green and makes the common case roughly three times slower — which is what the comment is there to prevent.

**Cross-module comment** — records a dependency that crosses a boundary and is therefore invisible at both ends: a provider's hard limit, a quirk of the schema, a coupling to a class in another file. It carries a pointer to where the fact is written in full, such as `see doc/read-after-write.md`. Ousterhout notes these are the hardest comments to place, because neither side is their natural home.

**Data structure member** — sits at a field or attribute and says what it represents. In Ruby this is the comment on a column, a constant, or an `attr_reader` whose name cannot carry the meaning on its own.

Tags are not prose and are not one of the four: `@param` and `@return` **declare** a type and are never accompanied by a sentence restating it. A duck type says more than a class name — `[String, #read]` states what the method actually requires. `# :nodoc:`, `# frozen_string_literal: true` and linter directives are directives to a tool, and stay wherever a tool needs them, tests and config included.

## What earns a comment

McConnell's list of what a comment can be is short, and most of it is worthless: a repeat of the code, an explanation of the code, a marker, a summary, a statement of **intent**, and information that cannot possibly be expressed by the code itself. Only the last two justify the line.

So, in order:

1. **Try the name first.** A better method name, a better parameter name, or a helper extracted and named after what it does removes the question outright. Kernighan and Plauger's rule — don't comment bad code, rewrite it.
2. **Delete test.** Remove the comment and read the code without it. If nothing was lost, it was a repeat of the code. Leave it deleted.
3. **Show test.** Ask whether what it says can be shown: as an input and an output, or as an outcome someone could observe. `# => "foo bar boo"` can be run and checked. "Without this guard, a second worker would charge the account twice" cannot — it describes a world that does not exist, which makes it rationale, and rationale belongs in the commit message and the pull request.
4. **Invariant test.** Where the comment states a rule, ask what happens when the rule is broken. If a test fails, that test is the documentation and the comment is a second copy that nothing keeps true. A comment earns its place where the breakage is silent: a leaked log line, one tenant reading another's data, two different renders sharing a cache key. Design by Contract has the vocabulary for these — precondition, postcondition, invariant — and an invariant is what most such comments are.

Published interfaces need interface comments as a matter of course; implementation code needs a comment only when one of these tests admits it, which is rarely.

## Rationale does not live in the file

The single most common defect is **rationale in place of documentation**: the comment explains why its author reached for something, in place of stating what the code guarantees or what a reader must not break. Ousterhout calls the interface-comment version of this **information leakage** — implementation detail in a comment whose job is to hide it.

**Bad** — rationale, and implementation leaking into an interface comment:

```ruby
# Read in a transaction so it reaches the writer. A caller writes an order and
# asks for the summary immediately afterwards; served by a replica that has not
# caught up, the summary would omit the very order it exists to report, and
# would still be persisted.
#
# @return [ActiveRecord::Relation<Order>] oldest first
def call
  Order.transaction { account.orders.order(:created_at).load }
end
```

**Good** — what the code cannot show, and where the rest is written down:

```ruby
# The transaction pins this read to the writer — see doc/read-after-write.md.
#
# @return [ActiveRecord::Relation<Order>]
def call
  Order.transaction { account.orders.order(:created_at).load }
end
```

The diff shows what changed, the commit message says why, and the pull request holds the argument. All three outlive the branch and none of them rots against the code.

## Named anti-patterns

**Redundant comment** — says what the line below already says.

**Bad:**

```ruby
# What state an order is in decides what it may become next, and lets a refund
# close a payment while it is still pending.
enum :state, {pending: 0, paid: 1, refunded: 2}, prefix: :state
```

**Good:**

```ruby
enum :state, {pending: 0, paid: 1, refunded: 2}, prefix: :state
```

The enum already lists every state an order can hold, and which transitions are legal is enforced elsewhere in the model; repeating it here creates a second copy that nothing keeps true. The same defect appears as prose beside a tag — `# @return [String] the text shown to the customer` over `def display_name` is the method's own name written twice. Delete the sentence, keep the tag.

**Journal comment** — the change history kept in the file, which version control already holds.

**Bad:**

```ruby
# Phase 2 of PROJ-412. Originally this used a JSON column on the order, but
# that made settled? a document dig, so we moved to rows instead.
class LineItem < ApplicationRecord
```

**Good:**

```ruby
# One line of an order.
#
# Amounts the system writes itself — a currency conversion, later a retried
# gateway fee — enter as their own line marked `system_origin`, never merged
# into a customer line: a charge the customer did not agree to must not come
# back to them as one they made.
class LineItem < ApplicationRecord
```

The second version is an interface comment followed by one invariant. It reads the same in a year to someone who never knew a JSON column had been considered. Ticket ids, phases and rejected alternatives go in the commit message.

**Attribution** — where a pattern came from, which review caught it, what its author verified before committing. It belongs nowhere in the file.

**Banner, or position marker** — `# --- Stage 9b: the usergroup gate ---` dividing a file or a test suite into labelled regions. If a region needs a name it wants to be a class, a context block, or a separate file.

**Mandated comment** — a doc comment written because a rule says every public method has one. On implementation code it produces a wall of restatement; the rule belongs to published interfaces only.

**Commented-out code** — delete it. Version control remembers it and nobody else will dare to.

**Explaining the framework** — what `includes` does, how a gem retries. Rails documents Rails; a copy in your file dates it to the version you wrote it against.

**Shortening when the answer is deletion.** Three versions of one comment, over the same line. Only the third is right.

**Bad** — as written:

```ruby
# The whole account is loaded at once because every order travels in the
# response; the line items ride along preloaded, so pairing a charge to its
# refund costs no further query.
account.orders.includes(:line_items)
```

**Bad** — told it was noise, made shorter: the same comment, fewer words:

```ruby
# Loaded whole because every order travels in the response, with line items
# preloaded so pairing a charge to its refund costs no further query.
account.orders.includes(:line_items)
```

**Good** — what `includes` does is Rails knowledge, and the call says the rest:

```ruby
account.orders.includes(:line_items)
```

A reviewer who says a comment should not exist is asking for it to be deleted. A shortened version comes back at the next review.

**A counterfactual** — any sentence of the form "without this, X would…". It describes a world that does not exist and cannot be checked against anything. It is rationale, and it goes in the pull request.

## Tests, config and migrations

Tests carry no prose at all. The test's name states the behaviour, helper names state the mechanism, and the assertion message carries what someone fixing a failure needs to know. If the behaviour is not legible from the name, the name is wrong and renaming it is the fix; a test that seems to need a comment is asking for a helper with a name. Banners dividing a suite into labelled regions are the most common offender.

In YAML workflows, JSON config and `.env` templates the setting's name and its value are the contract. Whoever needs to know why a value is what it is reads `git blame` and then the commit message. Migrations run once.

Directives a tool reads — `# frozen_string_literal: true`, `# rubocop:disable` — are not prose and stay.

## Why agent-written code drifts

The urge to write a comment fires hardest right after something has been worked out: how a gem retries, why one branch has to run before another. The discovery feels too expensive to leave unwritten. That feeling is a signal to stop rather than a licence to write.

Underneath sits a simpler motive. Code does not show effort — it either works or it does not. A comment does show effort. A sentence written so that a reviewer can see its author understood the system is a performance for the reviewer, and the reviewer is not who reads the file next year.

The instinct also relocates rather than dying. Removed from one place, it reappears in the next: delete a defensive default and it wants to become a caveat in a docstring; delete the caveat and it wants to become a test for a case that cannot happen; delete that test and it wants to become a paragraph in the pull request.

There is a reason the wrong register is the default. Public code is dominated by teaching artefacts and assessed work — tutorials, Stack Overflow answers, coursework, notebooks — all written for a reader who lacks the context. Code written for a colleague who will maintain it is mostly private. And public code contains only the comments that were written: one a reviewer deleted leaves no trace anywhere, so writing has millions of examples behind it and deleting has almost none.

## Documenting is its own pass

Documentation starts once the code works, and not before. A comment written mid-implementation is written by someone still deciding, so what it captures is the deciding rather than the decision. Write no comments during implementation at all, and the pass that follows has nothing to judge and only something to add.

**Auditing a file or a diff.** Read the diff with each comment beside its code. Grepping for comment lines produces a list with no code in it, and the delete test cannot be run against such a list: what comes out is rewriting by feel — polishing comments that should have been deleted, and keeping one that was plainly wrong about the line beneath it. When a comment contradicts its code, the first question is whether to delete it, not how to reword it. A change that touches only comments changes no behaviour, so it is verified by reading rather than by running the suite.

**Precedent is not a licence.** A neighbouring comment that breaks these rules is not permission to write another like it — it is the next thing to clean, by the Boy Scout Rule. Where an older block is the reason a new one took its shape, say so, because that older block is what keeps regenerating the pattern.

## Quick list

A comment that is none of the four kinds → delete it.
Repeat of the code → delete it; the language reads.
Prose beside a tag → delete the sentence, keep the tag.
Rationale in a docstring → state the guarantee; the reasoning goes in the commit and the pull request.
Implementation detail in an interface comment → information leakage; move it inside or drop it.
Journal comment, ticket ids, phases, alternatives → commit message.
Attribution — where it came from, who caught it → nowhere.
Banner or position marker → a class, a context block, or a file.
Mandated doc comment on implementation code → delete it; the rule is for published interfaces.
Commented-out code → delete it; version control remembers.
Explaining Rails or a gem → delete it; that layer documents itself.
A counterfactual, "without this, X would…" → pull request.
A rule a test already enforces → delete it; the test is the documentation.
A comment in a test → rename the test, or extract a named helper.
A comment in config or a migration → delete it; the setting name is the contract.
A comment contradicting its code → delete first; reword only if the fact still binds.
A question a better name would answer → rename, then see what is left to say.
A long comment above a private method → length belongs at a published interface.
Auditing by grepping comment lines → read the diff, each comment beside its code.

## References

- Steve McConnell, *Code Complete*, 2nd ed., ch. 32 — the kinds of comment, and why only intent and unexpressible information survive.
- Robert C. Martin, *Clean Code*, ch. 4 — the named anti-patterns: redundant, journal, banner, attribution, noise, mandated, commented-out code.
- John Ousterhout, *A Philosophy of Software Design*, ch. 12–16 — interface, implementation, cross-module and data-structure-member comments; information leakage; comments as the thing that makes abstraction possible.
- Bertrand Meyer, *Object-Oriented Software Construction* — Design by Contract: precondition, postcondition, invariant.
- Brian Kernighan and P. J. Plauger, *The Elements of Programming Style* — don't comment bad code, rewrite it.
- Oracle, *How to Write Doc Comments for the Javadoc Tool* — the doc comment as API specification, and the tag conventions YARD inherits.
- The YARD tag reference, for `@param`, `@return` and the rest as they are actually written in Ruby.
