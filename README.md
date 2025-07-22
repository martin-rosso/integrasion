# Nexo
Short description and motivation.

## Usage
How to use my plugin.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "nexo"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install nexo
```

Install good_job
Configure good_job
    max_threads:
    queues:

## Unhandled cases / TODO's

- Buscar la manera de wrappear los jobs en un with_tenant
    cuáles jobs?
    los que se disparan desde Google webhooks
    aunque quizá la posta es qeu esas routes estén scopeadas dentro del tid
- Testear el "no longer included in folder"
    o sea, modificar una rule y ver qué ande

- Al crear una Nexo::Folder, si falla el job de insert, que se muestre de
  alguna manera el error

- Restore locally discarded Events. It creates a new Google Calendar event?
- Recurring google events
- IMPORTANTE: loggear las exceptions de los jobs
- Llevar mucho control de los jobs y las exceptions que puedan surgir como
  ActiveRecord::PreparedStatementCacheExpired



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
