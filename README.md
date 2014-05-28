# Atr

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'atr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install atr

## What a stupid name
You likely think that this library has something to do with attributes, but it does not. So yes, it probably is a stupid name. Its named after

http://en.wikipedia.org/wiki/Ampex_ATR-100

in the spirit of following the celluloid/reel analog tape metaphor naming convention. But mostly because its short to type and Im lazy.

## What it does

Websockets/publishing events to connected clients, using the following as its backbone:

Reel, Celluloid&Celluloid::IO, and Redis

## Why use this over other websocket libraries for ruby?

Well dont use this yet because its incomplete. But the goal is mainly:

1) Make it easy to publish changes to the connected client
2) Event machine is a pile of *your preferred synonym for garbage*, so, didnt want to use any library that uses event machine. Use CelluloidIO and Reel as a foundation, because Reel is pretty cool.
3) Be able to publish events from anywhere in your application eventually, but for now just focus on making it easy to publish when resources themselves are created/updated/destroyed.
4) Single thread per websocket request that comes in. That lets you scope the websockets to the lowest level in your application that you choose to. I.E.

Lets say you have a subscriber which has many users. You can scope the publishing of events to the subscriber, and each connected user has its own websocket thread open to prevent chaotic behavior Ive seen happen in many other websocket implementations.

**So its strongly focused on listening for events, not triggering, maybe that will change in future maybe not IDK.**


### Usage

Include ::Atr::Publishable into
``` ruby
class Post < ::ActiveRecord::Base
  include ::Atr::Publishable
end
```

This will set up 3 publishing queues, and 3 after_action callbacks for the respective actions.
``` ruby
post.created
post.destroyed
post.updated
```

which will basically do

``` ruby

  def publish_created_event
    routing_key = self.class.build_routing_key_for_record_action(self, "created")
    // ("post.created")
    event_name = self.class.resource_action_routing_key("created")
    // ("post.created")

    record_created_event = ::Atr::Event.new(routing_key, event_name, self)

    ::Atr.publish_event(record_created_event)
  end
```
### Examples

``` ruby
class Post < ::ActiveRecord::Base
  include ::Atr::Publishable
end
```

This


### Client Side Example (from base angular controller)


## Purpose

Websockets for rails apps. The difference between this and any other websocket libraries

### Configuration



## Contributing

1. Fork it ( https://github.com/[my-github-username]/atr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
