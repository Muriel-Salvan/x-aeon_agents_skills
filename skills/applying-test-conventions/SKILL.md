---
name: applying-test-conventions
description: Applies idiomatic test conventions, structure, and best practices when writing or modifying unit tests. What this does is defining a set of rules to follow when dealing with any test file. Use this when the user is asking to create, edit, refactor, or review test files or when the project contains test scenarios.
---

# Applying test conventions

## Inform the user

- Always tell the user "SKILL: I am applying test conventions" to inform the user that you are running this skill.

## Conventions to be followed when testing

### Rule: Always write concise scenarios with a 3-steps structure: setup, run and expect

Always respect this structure for a test scenario:
1. Setup test data and mocks. Use defaults to only express test data relevant to the test scenario at hand.
2. Always call only the public interface of the class to be tested. Never call private methods of the interface.
3. Write simple expectations and assertions on results of the public interface of the class to be tested. Never assert results from private methods or internal states of the interface.
Use test helpers to make sure each step takes very few lines in each scenario.

#### Example: Incorrect

```ruby
it 'counts comments' do
  collection = MyCollection.new([
    { author: 'test_author1', comment: 'test_comment1' },
    { author: 'test_author1', comment: 'test_comment2' },
    { author: 'test_author2', comment: 'test_comment3' }
  ])
  comments = collection.instance_variable_get(:@items)
  expect(comments.size).to eq 3
end
```

#### Example: Correct

```ruby
# Helper providing test comments
def comment_factory(author: 'test_author', comment: 'test_comment')
  { author:, comment: }
end

it 'counts comments' do
  collection = MyCollection.new(3.times.map { comment_factory })
  expect(collection.nbr_elements).to eq 3
end
```

#### Rationale

Concise unit tests that have a clear structure are much easier to read and maintain.
Only relying on public methods to run and assert guarantees freedom to refactor the internals of the classes being tested, without impacting unit tests.

### Rule: Make sure each test scenario runs in an isolated way

Running scenarios in whatever order or group should never change the result of the test suite run.
If this is not the case, understand what could break the isolation of those unit tests and fix it.

#### Example: Incorrect

```ruby
it 'overrides the app default path from the environment' do
  ENV['OVERRIDE_APP_PATH'] = 'overridden_app/'
  expect(log_file()).to eq ['overridden_app/log.txt']
end
it 'logs actions' do
  app_run
  # The following expect fails with the suite, but passes when run solo.
  expect(File.read('default_app/log.txt')).to include 'Action has been run'
end
```

#### Example: Correct

```ruby
it 'overrides the app default path from the environment' do
  original_value = ENV['OVERRIDE_APP_PATH']
  ENV['OVERRIDE_APP_PATH'] = 'overridden_app/'
  begin
    expect(log_file()).to eq ['overridden_app/log.txt']
  ensure
    ENV['OVERRIDE_APP_PATH'] = original_value
  end
end
it 'logs actions' do
  FileUtils.rm_f 'default_app/log.txt'
  app_run
  expect(File.read('default_app/log.txt')).to include 'Action has been run'
end
```

#### Rationale

Unit tests should have deterministic behaviour, whether they are run alone or grouped with other tests.

## When to use it

- Always use it every time the user asks you to write or modify tests.
- Always use it every time another skill specifically mentions `skill: applying-test-conventions`.
- Always use it every time you need to write or modify tests.
