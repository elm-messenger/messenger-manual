#pagebreak()
= Events <events>

There are two types of events in Messenger: _World Event_ and _User Event_.
World event is the event Messenger can access while user events are the events users actually receive and it is a subset of the world event as some world event will not send to user.

```elm
type UserEvent
    = Tick
    | KeyDown Int
    | KeyUp Int
    | MouseDown Int ( Float, Float )
    | MouseUp Int ( Float, Float )
    | MouseWheel Int
```

Every general model (layer, component) will use `UserEvent` when updating. Recall the `update` function:

```elm
update : env -> event -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), ( env, Bool ) )
```

The last `Bool` is a _block_ indicator. Every general model is able to block event from sending to the next general components when updating.


Besides, it is essential to know that *the order of updating layers in a scene is opposite to the order of rendering layers in a scene*. This mechanism is designed to enable layers to block messages from passing to the layers behind it. 
This is useful when you are handling mouse events. When a layer handles a mouse click event, you don't want other layers to also be triggered.

== Keyboard Events

This includes both `KeyDown` and `KeyUp` events.

The parameter is `keyCode: Int`. `keyCode` is the #link("https://developer.mozilla.org/en-US/docs/Web/API/KeyboardEvent/keyCode")[keyCode] property of the keyboard event.

`keyCode` of common keys can be found in `Messenger.Misc.KeyCode` (in `messenger-extra`).

*Hint.* Users can use `globalData.pressedKeys` to get the current pressed keys.

== Mouse Events

This includes both `MouseDown` and `MouseUp` events.

The parameters are `button: Int`, `position: (Float, Float)`. The button has many values. 0 is the left mouse button and 2 is the right mouse button. More values can be found in #link("https://developer.mozilla.org/en-US/docs/Web/API/MouseEvent/button")[MDN].

`position` is the virtual coordinate of the mouse.

Users can use `judgeMouseRect` in `Messenger.Coordinate.Coordinates` to check whether the mouse is in a rectangle.

*Hint.* Users can use `globalData.pressedMouseButtons` to get the current pressed mouses.

== Tick Event

This event has no parameter. It is triggered every `timeInterval` (defined in user configuration file).

If users want to know the current timestamp, they can access it from `globalData.currentTimeStamp`. Users can convert it to timestamp in milliseconds by `Time.posixToMillis`.

*Note.* If an event of the game runs longer than `timeInterval`, all subscriptions will not be triggered until that event finishes.
