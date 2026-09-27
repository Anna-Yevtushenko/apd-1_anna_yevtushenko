# Plan

## Scope

Implement the necessary domain logic for StudyItem and StudyPlan without changing the published public API.

Need to implement:
- StudyItem validation
- duplicate id check in StudyPlan
- correct JSON decoding
- stable item sorting
- filtering by category
- counting minutes for incomplete items
- marking items as completed
- handling an unknown id
- additional custom tests

The optional importMerging() bonus was implemented separately from the main requirements

## Acceptance criteria

- StudyItem rejects an empty title
- StudyItem rejects estimatedMinutes <= 0
- if both values are invalid, blankTitle is returned first
- JSON decoding uses the same validation
- StudyPlan rejects duplicate id values
- if there are several duplicates, the first duplicate id is returned
- items are sorted by title, then by id
- StudyPlan.decode(from:) reads a top-level JSON array
- keyed JSON decoding through items also uses validation
- items(in:) returns only items from the selected category
- incompleteMinutes() counts minutes only for incomplete items
- markCompleted(id:) marks an item as completed
- calling markCompleted(id:) again keeps the correct state
- an unknown id returns unknownID
- all starter and additional tests pass

## Implementation steps

1) Implement StudyItem validation for the title and estimatedMinutes
2) Implement StudyPlan validation for duplicate IDs and sort items by title and id
3) Implement JSON decoding for StudyItem and StudyPlan
4) Implement items(in:) and incompleteMinutes()
5) Implement markCompleted(id:) and handle unknown IDs
6) Add at least 6 additional tests for the main functionality
7) Run swift test and make sure all tests pass

## Risks

- Custom init(from:) is needed to keep validation during decoding
- Duplicate ID validation should return the first duplicate ID
- Items should be sorted by title, then by id
- Public API and starter tests should not be changed
- markCompleted(id:) should work correctly when called more than once
- Hidden tests may check extra edge cases

## `swift test` verification

- swift test
