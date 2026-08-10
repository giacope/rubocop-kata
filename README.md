# rubocop-kata

A RuboCop plugin that replaces a pile of linter gems and config with one dependency. Install it and your `.rubocop.yml` shrinks to project-specific overrides. Everything else comes from the gem: a curated stack of RuboCop extensions, opinionated style defaults, and four house cops.

- **One dependency.** Bundles rubocop-rspec, rubocop-performance, rubocop-elegant, rubocop-packaging, and rubocop-thread_safety behind a single gem.
- **Opinionated defaults.** Methods under 5 lines, classes under 100, 4 parameters max, 120-column lines, double quotes, `NewCops: enable`. See [config/default.yml](config/default.yml).
- **Four house cops.** `Kata/AgentNoun`, `Kata/NoComments` (autocorrecting), `Kata/IoDiscipline`, `Kata/ProsePlacement`.

```ruby
class PaymentProcessor  # Kata/AgentNoun: `PaymentProcessor` names a doer;
end                     #   name the class for the thing it is, not the work it does.

class Payment           # OK
end
```

## Getting started

Add the gem to your `Gemfile`:

```ruby
gem "rubocop-kata", group: :development, require: false
```

Install it and point `.rubocop.yml` at the plugin:

```yaml
plugins:
  - rubocop-kata

AllCops:
  TargetRubyVersion: 3.4
```

```sh
bundle install
bundle exec rubocop
```

That's it. The plugin loads the bundled extensions and the shared defaults, so your `.rubocop.yml` keeps only what's specific to your project. Requires Ruby >= 3.4 and RuboCop ~> 1.75.

## The cops

| Cop | Default | What it enforces |
| --- | --- | --- |
| `Kata/AgentNoun` | on | Classes named for what they are, not `-er`/`-or` doers. Allow exceptions via `AllowedNames`. |
| `Kata/NoComments` | on | No prose comments; say it in the code. Magic comments, linter directives, and licence headers survive. Autocorrects. |
| `Kata/IoDiscipline` | on | No bare `puts`/`warn`/`pp`/`p` in `lib/`; write through an injected `@io` or an explicit receiver. |
| `Kata/ProsePlacement` | off | Sentence-length strings belong in the presentation layer. Enable with an `Include`/`Exclude` matching your layering. |

## The defaults

Double-quoted strings, `Metrics/MethodLength: 5`, `Metrics/ClassLength: 100`,
`Metrics/ParameterLists: 4`, 120-column lines, endless methods on one line,
`rescue => error`, `NewCops: enable`, and heredocs counted as one line in
spec examples. See
[config/default.yml](config/default.yml).

## License

MIT.
