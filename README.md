HTTP Request Rate Limiter for Rack Applications
===============================================

This is [Rack][] middleware that provides logic for rate-limiting incoming
HTTP requests to Rack applications. You can use `Rack::Throttle` with any
Ruby web framework based on Rack, including with Ruby on Rails and with
Sinatra.

* <https://github.com/bendiken/rack-throttle>

Features
--------

* Throttles a Rack application by enforcing a minimum time interval between
  subsequent HTTP requests from a particular client, as well as by defining
  a maximum number of allowed HTTP requests per a given time period (per minute,
  hourly, or daily).
* Compatible with any Rack application and any Rack-based framework.
* Stores rate-limiting counters in any key/value store implementation that
  responds to `#[]`/`#[]=` (like Ruby's hashes) or to `#get`/`#set` (like
  memcached or Redis).
* Compatible with the [gdbm][] binding included in Ruby's standard library.
* Compatible with the [memcached][], [memcache-client][], [memcache][] and
  [redis][] gems.
* Compatible with [Heroku][]'s [memcached add-on][Heroku memcache]
  (currently available as a free beta service).

Examples
--------

### Adding throttling to a Rails application

```ruby
# config/application.rb
require 'rack/throttle'

class Application < Rails::Application
  config.middleware.use Rack::Throttle::Interval
end
```

### Adding throttling to a Sinatra application

```ruby
#!/usr/bin/env ruby -rubygems
require 'sinatra'
require 'rack/throttle'

use Rack::Throttle::Interval

get('/hello') { "Hello, world!\n" }
```

### Adding throttling to a Rackup application

```ruby
#!/usr/bin/env rackup
require 'rack/throttle'

use Rack::Throttle::Interval

run lambda { |env| [200, {'Content-Type' => 'text/plain'}, "Hello, world!\n"] }
```

### Enforcing a minimum 3-second interval between requests

```ruby
use Rack::Throttle::Interval, :min => 3.0
```

### Allowing a maximum of 1 request per second

```ruby
use Rack::Throttle::Second,   :max => 1
```

### Allowing a maximum of 60 requests per minute

```ruby
use Rack::Throttle::Minute,   :max => 60
```

### Allowing a maximum of 100 requests per hour

```ruby
use Rack::Throttle::Hourly,   :max => 100
```

### Allowing a maximum of 1,000 requests per day

```ruby
use Rack::Throttle::Daily,    :max => 1000
```

### Combining various throttling constraints into one overall policy

```ruby
use Rack::Throttle::Daily,    :max => 1000  # requests
use Rack::Throttle::Hourly,   :max => 100   # requests
use Rack::Throttle::Minute,   :max => 60    # requests
use Rack::Throttle::Second,   :max => 1     # requests
use Rack::Throttle::Interval, :min => 3.0   # seconds
```

### Storing the rate-limiting counters in a GDBM database

```ruby
require 'gdbm'

use Rack::Throttle::Interval, :cache => GDBM.new('tmp/throttle.db')
```

### Storing the rate-limiting counters on a Memcached server

```ruby
require 'memcached'

use Rack::Throttle::Interval, :cache => Memcached.new, :key_prefix => :throttle
```

### Storing the rate-limiting counters on a Redis server

```ruby
require 'redis'

use Rack::Throttle::Interval, :cache => Redis.new, :key_prefix => :throttle
```

Throttling Strategies
---------------------

`Rack::Throttle` supports four built-in throttling strategies:

* `Rack::Throttle::Interval`: Throttles the application by enforcing a
  minimum interval (by default, 1 second) between subsequent HTTP requests.
* `Rack::Throttle::Hourly`: Throttles the application by defining a
  maximum number of allowed HTTP requests per hour (by default, 3,600
  requests per 60 minutes, which works out to an average of 1 request per
  second).
* `Rack::Throttle::Daily`: Throttles the application by defining a
  maximum number of allowed HTTP requests per day (by default, 86,400
  requests per 24 hours, which works out to an average of 1 request per
  second).
* `Rack::Throttle::Minute`: Throttles the application by defining a
  maximum number of allowed HTTP requests per minute (by default, 60
  requests per 1 minute, which works out to an average of 1 request per
  second).
* `Rack::Throttle::Second`: Throttles the application by defining a
  maximum number of allowed HTTP requests per second (by default, 1
  request per second).
* `Rack::Throttle::Rules`: Throttles the application by defining
  different rules of allowed HTTP request per time_window based on the
  request method and the request paths, or use a default.

You can fully customize the implementation details of any of these strategies
by simply subclassing one of the aforementioned default implementations.
And, of course, should your application-specific requirements be
significantly more complex than what we've provided for, you can also define
entirely new kinds of throttling strategies by subclassing the
`Rack::Throttle::Limiter` base class directly.

### Example

Customize the `max_per_second` to be different depending on the request's method.

```ruby
class Rack::Throttle::RequestMethod < Rack::Throttle::Second

  def max_per_second(request = nil)
    return (options[:max_per_second] || options[:max] || 1) unless request
    if request.request_method == "POST"
      4
    else
      10
    end
  end
  alias_method :max_per_window, :max_per_second

end
```

Passing the correct options for `Rules` strategy.

```ruby
rules = [
  { method: "POST", limit: 5 },
  { method: "GET", limit: 10 },
  { method: "GET", path: "/users/.*/profile", limit: 3 },
  { method: "GET", path: "/users/.*/reset_password", limit: 1 },
  { method: "GET", path: "/external/callback", whitelisted: true }
]
ip_whitelist = [
  "1.2.3.4",
  "5.6.7.8"
]
default = 10


use Rack::Throttle::Rules, rules: rules, ip_whitelist: ip_whitelist, default: default
```

This configuration would allow a maximum of 3 profile requests per second (default), i
1 reset password requests per second, 5 POST and 10 GET requests per second
(always also based on the IPaddress). Additionally it would whitelist the external callback
and add a ip-whitelisting for the given ips.

Rules are checked in this order:
* ip whitelist
* rules with `paths`,
* rules with `methods` only,
* `default`.

It is possible to set the time window for this strategy to: `:second` (default), `:minute`, `:hour` or `:day`, to change the check interval to these windows.

```ruby
use Rack::Throttle::Rules, limits: limits, time_window: :minute
```


HTTP Client Identification
--------------------------

The rate-limiting counters stored and maintained by `Rack::Throttle` are
keyed to unique HTTP clients.

By default, HTTP clients are uniquely identified by their IP address as
returned by `Rack::Request#ip`. If you wish to instead use a more granular,
application-specific identifier such as a session key or a user account
name, you need only subclass a throttling strategy implementation and
override the `#client_identifier` method.

HTTP Response Codes and Headers
-------------------------------

### 403 Forbidden (Rate Limit Exceeded)

When a client exceeds their rate limit, `Rack::Throttle` by default returns
a "403 Forbidden" response with an associated "Rate Limit Exceeded" message
in the response body.

An HTTP 403 response means that the server understood the request, but is
refusing to respond to it and an accompanying message will explain why.
This indicates an error on the client's part in exceeding the rate limits
outlined in the acceptable use policy for the site, service, or API.

### 503 Service Unavailable (Rate Limit Exceeded)

However, there exists a widespread practice of instead returning a "503
Service Unavailable" response when a client exceeds the set rate limits.
This is technically dubious because it indicates an error on the server's
part, which is certainly not the case with rate limiting - it was the client
that committed the oops, not the server.

An HTTP 503 response would be correct in situations where the server was
genuinely overloaded and couldn't handle more requests, but for rate
limiting an HTTP 403 response is more appropriate. Nonetheless, if you think
otherwise, `Rack::Throttle` does allow you to override the returned HTTP
status code by passing in a `:code => 503` option when constructing a
`Rack::Throttle::Limiter` instance.

Dependencies
------------

* [Rack](http://rubygems.org/gems/rack) (>= 1.0.0)

Installation
------------

The recommended installation method is via [RubyGems](http://rubygems.org/).
To install the latest official release of the gem, do:

    % [sudo] gem install rack-throttle

Authors
-------

* [Arto Bendiken](https://gratipay.com/bendiken) - <http://ar.to/>

Contributors
------------

* [Brendon Murphy](https://github.com/bemurphy)
* [Hendrik Kleinwaechter](https://github.com/hendricius)
* [Karel Minarik](https://github.com/karmi)
* [Keita Urashima](https://github.com/ursm)
* [Leonid Beder](https://github.com/lbeder)
* [TJ Singleton](https://github.com/tjsingleton)
* [Winfield Peterson](https://github.com/wpeterson)
* [Dean Galvin](https://github.com/freekingdean)

Contributing
------------

* Do your best to adhere to the existing coding conventions and idioms.
* Don't use hard tabs, and don't leave trailing whitespace on any line.
  Before committing, run `git diff --check` to make sure of this.
* Do document every method you add using [YARD][] annotations. Read the
  [tutorial][YARD-GS] or just look at the existing code for examples.
* Don't touch the gemspec or `VERSION` files. If you need to change them,
  do so on your private branch only.
* Do feel free to add yourself to the `CREDITS` file and the
  corresponding list in the the `README`. Alphabetical order applies.
* Don't touch the `AUTHORS` file. If your contributions are significant
  enough, be assured we will eventually add you in there.

License
-------

This is free and unencumbered public domain software. For more information,
see <http://unlicense.org/> or the accompanying `UNLICENSE` file.

[Rack]:            http://rack.rubyforge.org/
[gdbm]:            http://ruby-doc.org/stdlib/libdoc/gdbm/rdoc/classes/GDBM.html
[memcached]:       http://rubygems.org/gems/memcached
[memcache-client]: http://rubygems.org/gems/memcache-client
[memcache]:        http://rubygems.org/gems/memcache
[redis]:           http://rubygems.org/gems/redis
[Heroku]:          http://heroku.com/
[Heroku memcache]: http://docs.heroku.com/memcache
[YARD]:            http://yardoc.org/
[YARD-GS]:         http://rubydoc.info/docs/yard/file/docs/GettingStarted.md
