## What a stupid name
You likely think that this library has something to do with attributes, but it does not. So yes, it probably is a stupid name. Its named after

http://en.wikipedia.org/wiki/Ampex_ATR-100

in the spirit of following the celluloid/reel analog tape metaphor naming convention. But mostly because its short to type and Im lazy.

## What it does

Websockets/publishing events to connected clients, using the following as its backbone:

Reel, Celluloid&Celluloid::IO, and Redis

## Why use this over other websocket libraries for ruby?

Well dont use this yet because its incomplete. But the goal is mainly:

1. Make it easy to publish changes to the connected client
2. Event machine is a pile of *your preferred synonym for garbage*, so, didnt want to use any library that uses event machine. Use CelluloidIO and Reel as a foundation, because Reel is pretty cool.
3. Be able to publish events from anywhere in your application eventually, but for now just focus on making it easy to publish when resources themselves are created/updated/destroyed.
4. Single thread per websocket request that comes in. That lets you scope the websockets to the lowest level in your application that you choose to. I.E.

Lets say you have a subscriber which has many users. You can scope the publishing of events to the subscriber, and each connected user has its own websocket thread open to prevent chaotic behavior Ive seen happen in many other websocket implementations.

**So its strongly focused on listening for events, not triggering, maybe that will change in future maybe not IDK.**

### Usage

To generate events upon actions taking place within your application, include
``` ruby
include ::Atr::Publishable
```

Into your model. Example

### How it works

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
  // post.created
  event_name = self.class.resource_action_routing_key("created")
  // post.created

  record_created_event = ::Atr::Event.new(routing_key, event_name, self)

  ::Atr.publish_event(record_created_event)
end
```

Etc Etc for updated/destroyed.

**So to walkthrough publish_created_event above**

1. First, we create routing key based on the name of the class, + the action. Additionally if you scope the event, this will be reflected in the routing key (i.e. you can scope it to a particular subscriber or user or whatever, so you can share state and or sync events between multiple users belonging to the same organization). (more on that later)
2. we generate an event name based on name of the class + the action (scope doesent matter we just want to describe what happened)
3. wrap the record in an ::Atr::Event object
4. Publish the event, this will Marshal.dump the record through redis, and if there is a subscriber listening on the routing key of the event, the websocket connection (Atr::Reactor) instance, will receive that message, unmarshall it back into the original event object, and write it to the websocket.

This allows us to publish events with pretty fine grained precision, and broadcast them to specific subscribers. If you're unfamiliar with redis pub/sub, rundown is, if you are listening to the channel at the moment the message is published, the subscriber will get it, otherwise it removes it and pays no regard to the msssage being published. No durability, but thats what we want for websocket events.

### How the websocket server works

The websocket server works differently than many other implementations, in that its by design a standalone process, which acts mainly as a router for websocket connections that come in. When a valid websocket request comes in, it will launch a brand new thread, close the original request and detatch the websocket, and pass it into the object which controls the websocket (::Atr::Reactor, for lack of a better name ATM). This once again is mainly about scope, and has arisen out of the past frustrations of using websocket libraries which were built on event machine which I spent countless hours debugging, issues like duplicate events.

Its also IMO the ideal way to model a socket server, 1 thread belonging to each client which connects to it. Close the thread when they disconnect. Only use resources for whats currently relevant.

### Starting the socket server
``` ruby
bx atr_server start --server_host="127.0.0.1" --server_port="7777"
```
(the defaults, the above is the same as)

``` ruby
bx atr_server start
```

### Connecting to socket server via JS

``` javascript
var ws = new WebSocket("ws://127.0.0.1:7777");
```

### Listen for events
``` javascript
ws.onmessage = function(e) {
  var event, parsed_event;

  event = e.data;
  parsed_event = JSON.parse(event);
  console.log(parsed_event);
}
```

### Full Example (including client side)

Here is a snippet of code from an inprogress sideproject, using a base angular controller (using angular-ui-router). This is enough to listen to any event in the application, and display growl notifications for all connected members of the "organization", notifying them of what action took place.

``` javascript
  $stateProvider.state('base', {
    abstract: false,
    url: "",
    templateUrl: '/templates/base.html',
    resolve: {
      current_organization: function(CurrentOrganization) {
        return CurrentOrganization.get();
      },
      current_user: function(CurrentUser) {
        return CurrentUser.get();
      }
    },
    controller: function($scope, current_organization, current_user, $state, growl) {
      $scope.current_organization = current_organization;
      $scope.current_user = current_user;

      $scope.websocket_params = {
        organization: current_organization.id
      };

      $scope.websocket_base_url = "ws://127.0.0.1:7777";

      $scope.websocketUrl = function() {
        return [ $scope.websocket_base_url, _.flatten(_.pairs(myscope.websocket_params)).join("/") ].join("/");
      };

      $scope.ws = new WebSocket($scope.websocketUrl());

      $scope.ws.onopen = function() {
        console.log('opening ws con');
        $scope.ws.send(JSON.stringify({action: "do.something." + current_user.id}));
      };

      $scope.ws.onmessage = function(e) {
        $scope.dispatchMessage(e.data);
      };

      $scope.ws.onclose = function() {
        alert("websocket connection closed");
      };

      $scope.do_something = function() {
        $scope.ws.send('do_something');
      };

      $scope.dispatchMessage = function (message) {
        var event = JSON.parse(message);
        $scope.$root.$broadcast(event.name, event);
      };

      _.each(current_organization.websocket_channels, function(channel){
        $scope.$on(channel, function(e, websocket_event){
          console.log(websocket_event);
          growl.addInfoMessage(websocket_event.name);
          $scope.$root.$digest();
        });
      });
    }
  });
```

**Initializer**
``` ruby
::Atr.configure do |config|
  config.authenticate_with = ::WebsocketAuthenticator
  config.scope_with = ::WebsocketScope
  config.event_serializer = ::WebsocketEventSerializer
end
```

**NOTE:** the following are bad examples. I.e. Im not really authenticating anything im just checking that the websocket request has a valid organization id in the path, really youd want to use auth token or some way to validate the request. But it's so low level that it should be easy to do whatever you need to w/this middlewarish pattern for scoping/validating.

**Websocket Authenticator**

``` ruby
class WebsocketAuthenticator < ::Atr::RequestAuthenticator
  def matches?
    current_organization.present?
  end

  def current_organization
    @current_organization ||= ::Client::Organization.find(segs[1])
  end

  def segs
    @segs ||= request.url.split("/").reject(&:empty?)
  end
end
```
**Websocket Scope**
``` ruby
class WebsocketScope < ::Atr::RequestScope
  VALID_SCOPE_KEYS = ["organization"]

  def segs
    @segs ||= request.url.split("/").reject(&:empty?)
  end

  def routing_key
    [segs[0], segs[1]].join(".")
  end

  def valid?
    VALID_SCOPE_KEYS.include?(segs[0]) && segs.size == 2
  end
end
```

You also have access to query string params as a hash with params method in either class.


**Event Serializer**

Im using ActiveModel Serializers, but any serializer that is instantiated as new, passes in the record, and is serialized via the .to_json method should work (so if you want to use decorators or a custom class or something).

``` ruby
class WebsocketEventSerializer < BaseSerializer
  self.root = false

  attributes :id, :name, :record, :routing_key, :record, :occured_at, :time_ago

  def time_ago
    distance_of_time_in_words(object.occured_at, ::DateTime.now)
  end

  def action
    object.name.split(".").pop
  end
end
```

**Model, and scoping the publication of the event**

``` ruby
class Post < ::ActiveRecord::Base
  include ::Atr::Publishable
  publication_scope :organization_id
end
```

Kind of ghetto, but works for now, basically, this will using the organization_id attribute, and prepend the key (without the _id), i.e.

organization.#{organization_id}.post.created

Whenever creating routing keys when publishing events. (only for that specific resource though, so you probably want to add that same publication scope, and define a method that gets to that scope for each of your models requiring publication).

Last but not least, for a programatic way of knowing which channels to listen to I.E., in the javascript above

``` javascript
_.each(current_organization.websocket_channels, function(channel){
  $scope.$on(channel, function(e, websocket_event){
    console.log(websocket_event);
  });
});
```

You can get the channels via the registry

``` ruby
def websocket_channels
  ::Atr::Registry.channels
end
```

### If any of how it works is confusing, pay attention to the following as it may clear things up:

**NOTE:** the redis pubsub mechanism is only concerned about the publication scope, i.e.

organization.1234.post.created

But since each connection launches a new thread, listenting to that specific channel, we can then broadcast the event itself to the websocket as

post.created

and it will be scoped appropriately to correct client, as its only actually written out to the websocket threads belonging to that organization.

(we actually just write the entire event object to the socket and the client side JS is responsible for figuring out how to route it and what not)

### Scoping and authentication

Quick explanation is, it works much like Rack middleware. Configure a class and it will be passed the request object on initialize.

Class must respond to matches? which will determine whether the request is valid, and in the case of scope_with, will scope the publishing of the record, i.e.

organization.1234.post.created
rather than post.created

### Advanced Configuration
Todo: explain scoping and authenticating the websocket requests and provide better example.

### Important To Do
Allow target redis instance to actually be configurable. Right now just running locally so connects to redis defaults.

### Configuration / Initializer

``` ruby
::Atr.configure do |config|
  config.authenticate_with = ::WebsocketAuthenticator
  config.scope_with = ::WebsocketScope
  config.event_serializer = ::WebsocketEventSerializer
end
```

### FYIs / Gotchas / Notes to self

ActiveRecord opens new connection each time request comes in, Im manually closing it as we do need to have AR loaded for the purposes of reading the schema, but after that we dont need a connection at all since all the marshaling/unmarshaling the event does not require it. (As far as I can see at least). The main application w/ the publisher, does the serialization, so the server doesen't need the connections. So no used up connections per the websocket threads that are created. Winning.

If I decide to go the route of websocket rails to allow cruding beyond just listening as it stands right now, the websocket connections will need to use connection pool.

## Installation

Add this line to your application's Gemfile:

    gem 'atr'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install atr


## Contributing

1. Fork it ( https://github.com/[my-github-username]/atr/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
