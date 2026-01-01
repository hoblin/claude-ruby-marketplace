# Thoughts Directory Structure

This directory contains developer thoughts and notes for the claude-ruby-marketplace repository.
It is managed by the thoughts sync scripts and should not be committed to the code repository.

## Structure

- `hoblin/` - Your personal notes for this repository (symlink to ~/thoughts/repos/claude-ruby-marketplace/hoblin)
- `shared/` - Team-shared notes for this repository (symlink to ~/thoughts/repos/claude-ruby-marketplace/shared)
- `global/` - Cross-repository thoughts (symlink to ~/thoughts/global)
  - `hoblin/` - Personal notes that apply across all repositories
  - `shared/` - Team-shared notes that apply across all repositories

## Usage

Create markdown files in these directories to document:
- Architecture decisions
- Design notes
- TODO items
- Investigation results
- Any other development thoughts

Quick access:
- `thoughts/hoblin/` for your repo-specific notes (most common)
- `thoughts/shared/` for team-shared repo notes
- `thoughts/global/hoblin/` for your cross-repo notes

## Commands

- `thoughts-sync` - Commit and push thoughts changes
- `thoughts-status` - Show thoughts repository status

## Important

- Never commit the thoughts/ directory to your code repository
- Use `thoughts-sync` to manually sync changes
- Use `thoughts-status` to see sync status
