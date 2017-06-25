# hubot-sensu

A hubot script that silences sensu on servers

See [`src/sensu.coffee`](src/sensu.coffee) for full documentation.

## Installation

In hubot project repo, run:

`npm install hubot-sensu --save`

Then add **hubot-sensu** to your `external-scripts.json`:

```json
[
  "hubot-sensu"
]
```

## Sample Interaction

```
user1>> hubot sensu get silenced
hubot>> The following db servers are silenced:
client:awasome.server.com
...
```

## NPM Module

https://www.npmjs.com/package/hubot-sensu
