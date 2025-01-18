#import "@preview/fletcher:0.4.5" as fletcher: diagram, node, edge

#pagebreak()
= Components

Components can be considered as the basic elements in the game. Every layer contains several components and each type of component has its own logic.

Components are versatile. Users can abstract almost every single thing in their game as a component. For instance, a character that can move and attack, the bullet fired by the character, a settings panel, an abstract concept like "ability to cast magic", and a manager to manage one specific type of components. You may even embed components into a component! Properly implementing objects and abstract concepts as components can greatly reduce your workload. 

Components are customizable. Users can easily define all the details of a component. One component type can have its unique data type, matcher, initialization, update and render.

Components are flexible. Users can organize different types of components whatever they like. They can set one component type be a sub-type of other component. They can also put different type of components into one set, so that the components can share a basic data type, and send the same type of messages to each other easily. Users can always put components whose types are in the same set, into one list in layer.

Using components allows users to simplify a complex feature and manage it step by step. Moreover, it provides a simpler and more flexible way for users to organize code. So it is necessary to use components to implement most of the logics for a complex game.

== Basic Model <component>

Basically the component type is inherited from the general model as follows:

```elm
type alias ConcreteUserComponent data cdata userdata tar msg bdata scenemsg =
    ConcreteGeneralModel data (Env cdata userdata) UserEvent tar msg ( Renderable, Int ) bdata (SceneOutputMsg scenemsg userdata)
type alias AbstractComponent cdata userdata tar msg bdata scenemsg =
    AbstractGeneralModel (Env cdata userdata) UserEvent tar msg ( Renderable, Int ) bdata (SceneOutputMsg scenemsg userdata)
```

So for a single component, it works just like how general model does.

The parameter `data` represents the data type of this type of component. It is unique since users can set it freely.
`bdata`, which stands for _Base Data_, represents the type that will be the same among all the types of components in one set.

Note the common data is the data that shared among all the components, so every component can view or change the only copy of the common data. However, base data is the data that every component has, and only the type is shared.

For instance, in a platform game, common data may include gravity while base data may include positions and velocities.

The `render` type is aliased to `(Renderable, Int)`. The second entry is the #link("https://developer.mozilla.org/en-US/docs/Web/CSS/z-index")[z-index] property of the component. Each component may have different z-index value.

== User Components

User components are the components that are mostly used. A user component should be attached to a specific scene, then it can only be used in that scene.

To understand the usage of the components better, let's make an example.

```bash
# Create a new scene named Game
messenger scene Game

# Create a new type of component in Game scene
messenger component Game Comp

# Create a new layer with components in Game Scene
messenger layer -c Game A
```

Addition to set the data type of `Comp`, set the data type for initialize a `Comp` is necessary. Since we would like to determine the position, size and color when initializing, add codes in `Scenes/Home/Components/ComponentBase.elm`:

```elm
type alias Init =
    { left : Float
    , top : Float
    , width : Float
    , height : Float
    , color : Color
    }
type alias Data =
    { left : Float
    , top : Float
    , width : Float
    , height : Float
    , color : Color
    }
```

Then add the message type for initialization in `ComponentMsg`.

However, the data set in `ComponentBase.elm` will be applied to all types of components. So it is a choice to set the init data and message type for every single type of component. Users can create a file named `Init.elm` in `Scene/Home/Components/Comp` to store them separately. Users can also use the option `--init` or `-i` to do this when creating the component. Don't forget to import it in `ComponentBase.elm`.

```bash
messenger component -i Game Comp
```

Then draw a rectangle based on the component data in `view` function. But it will not be rendered on screen now since it has not been added to any layer yet. So let's add two components when initialize the layer and render them using `viewComponents`:

```elm
import Scenes.Home.Components.Comp.Model as Rect
import Scenes.Home.Components.Comp.Msg as RectMsg
...
type alias Data =
    { components : List (AbstractComponent SceneCommonData UserData ComponentTarget ComponentMsg BaseData SceneMsg)
    }
init : LayerInit SceneCommonData UserData LayerMsg Data
init env initMsg =
    Data
        [ Rect.component ( RectangleInit <| RectMsg.Init 150 150 200 200 Color.blue ) env
        , Rect.component ( RectangleInit <| RectMsg.Init 200 200 200 200 Color.red ) env
        ]
...
view : LayerView SceneCommonData UserData Data
view env data =
    viewComponents env data.components
```

Note that `Data` and `view` function has been provided.

Now one red rectangle on a blue one on screen.

Then try to add a simple logic that when you left click the rectangle, it turns black:

```elm
update : ComponentUpdate SceneCommonData Data UserData SceneMsg ComponentTarget ComponentMsg BaseData
update env evnt data basedata =
    case evnt of
        MouseDown 0 pos ->
            if judgeMouseRect pos ( data.left, data.top ) ( data.width, data.height ) then
                ( ( { data | color = Color.black }, basedata ), [], ( env, False ) )

            else
                ( ( data, basedata ), [], ( env, False ) )

        _ ->
            ( ( data, basedata ), [], ( env, False ) )
```

Then update all the components in layer using `updateComponents`, which has been done in `A/Model.elm` by default.

=== Message Blocking

Our code seems to work well when we click the non-overlapping part of the two rectangles. But when we click the overlapping part of them, both of them turns black, which is not expected. The issue has been mentioned in @events. So we can solve this problem by changing the block value from `False` to `True`.

```elm
( ( { data | color = Color.black }, basedata ), [], ( env, True ) )
```

What if add a layer `B` to the scene? Create a new layer B:

```bash
messenger layer -c Game B
```

Then add it to the scene. Note to put `B` before `A` in the layer list so that layer `A` will update before `B` and render after `B`. See @layers and @events.

Add two rectangle components to `B` in position (100, 100) and (250, 250) with size (200, 200), which means they will be overlapped by the components in `A`. Left click one component in A, the components in `B` do not turn black. It shows the block indicator will be passed by the order of updating.

=== Message Communication

The work we did until now is just to update the component itself. But how to communicate with other components and layers? Let's add a logic that when user click one rectangle, the color of the other one turns green.

First of all, set a message type in `Components/Comp/Init.elm` is necessary. Since the only message needed to pass is the color to change, add:

```elm
type alias Msg =
    Color
```

Then add it to `ComponentMsg` in `ComponentBase.elm`. How a component reacts with the messages is determined in `updaterec`:

```elm
updaterec : ComponentUpdateRec SceneCommonData Data UserData SceneMsg ComponentTarget ComponentMsg BaseData
updaterec env msg data basedata =
    case msg of
        RectangleMsg c ->
            ( ( { data | color = c }, basedata ), [], env )

        _ ->
            ( ( data, basedata ), [], env )
```

Since the message is going to send from one component to the other, the target and matcher system need to be improved. An id can be added for every components to identify themselves. Let's add `id : Int` in `Data` and `InitData`. Then change `ComponentTarget` type into `Int`, and modify the `matcher`:

```elm
matcher : ComponentMatcher Data BaseData ComponentTarget
matcher data basedata tar =
    tar == data.id
```

`update` function is also need to be updated so that it can send message to other components when mouse left click.

```elm
  ( ( { data | color = Color.black }, basedata )
  , List.filterMap
      (\n ->
          if n /= data.id then
              Just <| Other ( n, RectangleMsg green )

          else
              Nothing
      )
    <|
      List.range 0 1   -- use 0 1 because there are just 2 components
  , ( env, True )
  )
```

Run `make` and see the result now!

Note that when click a component in one layer, the components in the other layer won't change their colors. So components cannot directly communicate across layers, they have to send message to each other via their parent layer.

Now the issue is to communicate between layer and component. Sending message to components from a layer is similar to how from component. But a layer cannot directly deal with the messages from components in `updaterec` because the `updaterec` function of layer is used to handle the message from other layers. 

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((-2, 0), [`A`], corner-radius: 0pt),
    edge((-2, 0), (2, 0), `LayerMsg`, "<->",),
    node((-3, 1), [Comp 1], corner-radius: 2pt),
    edge((-3, 1), (-2, 0), `ComponentMsg`, "<->"),
    node((-1, 1), [Comp 2], corner-radius: 2pt),
    edge((-1, 1), (-2, 0), `ComponentMsg`, "<->"),
    edge((-3, 1), (-1, 1), `ComponentMsg`, "<->"),
    node((2, 0), [`B`], corner-radius: 0pt),
    node((3, 1), [Comp 2], corner-radius: 2pt),
    edge((3, 1), (2, 0), `ComponentMsg`, "<->"),
    node((1, 1), [Comp 1], corner-radius: 2pt),
    edge((1, 1), (2, 0), `ComponentMsg`, "<->"),
    edge((3, 1), (1, 1), `ComponentMsg`, "<->"),
  )
]

Therefore, a handler for the messages from components should be added. We can simply modify the handler provide by default:
```elm
handleComponentMsg : Handler Data SceneCommonData UserData LayerTarget LayerMsg SceneMsg ComponentMsg
handleComponentMsg env compmsg data =
    case compmsg of
        SOMMsg som ->
            ( data, [ Parent <| SOMMsg som ], env )

        OtherMsg msg ->
            case msg of
                RectangleMsg color ->
                    let
                        _ =
                            Debug.log "msg" color
                    in
                    ( data, [], env )

                _ ->
                    ( data, [], env )
```
In this way, components and their parent layer can communicate easily.

=== z-index 

Notice that the red rectangle is on the top of the blue one now. How to reverse their order to make the blue one on the top? A very simple way is to directly change their order in the initial list in layer. Since the render order depends on the order in list by default, the render order reverses in this way.

However, this method doesn't work in some cases, especially when a new component is added during the game or the render order need to be changed during the game. They are the situation that z-index should be used.

Users can decide the z-index dynamically based on data or environment in `view` function. Take the previous issue for example, the requirement can be implemented by adding a new value `order` in `data` which determines the z-index.

The source code in this part can be found #link("https://github.com/linsyking/messenger-examples/tree/main/layers")[here].

== Portable Components

*Warning. This feature is highly experimental.* To use portable components, you need to add `messenger-extra` to your dependencies.

In brief, portable components are sets of interfaces that can be transformed automatically into user components. Portable components aim to provide more flexibilities on components.

The characteristics of portable components include:

- Users can use portable components across scenes and even across projects
- Portable components could be written in a library
- They do not have the base data
- They cannot get the common data
- Users need to set the `Msg` and `Target` type for every portable component
- Users who use portable components need to provide a codec to transform the messages and targets

*Warning*. Portable components are only useful when you are designing a component applicable to many different scenes (e.g. UI element). However, if your component is tightly connected to the scene (in most cases), please use scene prototype discussed in @sceneproto. It allows you to reuse scene and components. Think carefully whether you really need portable components before using it.

Specifically, you need to provide codecs with the following types:

```elm
type alias PortableMsgCodec specificmsg generalmsg =
    { encode : generalmsg -> specificmsg
    , decode : specificmsg -> generalmsg
    }
type alias PortableTarCodec specifictar generaltar =
    { encode : generaltar -> specifictar
    , decode : specifictar -> generaltar
    }
```

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    edge((-3, 0), (-1, 0), `generalmsg`, "->"),
    node((-1, 0), [`encode`], corner-radius: 0pt),
    edge((-1, 0), (0, 1), `specificmsg`, "->", bend: -20deg),
    node((0, 1), [Portable component], corner-radius: 2pt),
    edge((0, 1), (1, 0), `specificmsg`, "->", bend: -20deg),
    node((1, 0), [`decode`], corner-radius: 0pt),
    edge((1, 0), (3, 0), `generalmsg`, "->"),
    node(enclose: ((-1, 0), (0, 1), (1, 0)), stroke: (paint: blue, dash: "dashed"), inset: 8pt),
    node((0, 0), text(fill: blue)[Generated user component], stroke: none)
  )
]

After that, users can use the function below to generate user components from portable ones:

```elm
translatePortableComponent : ConcretePortableComponent data userdata tar msg scenemsg -> PortableTarCodec tar gtar -> PortableMsgCodec msg gmsg -> bdata -> Int -> ConcreteUserComponent data cdata userdata gtar gmsg bdata scenemsg
```

Currently, portable components are experimental, so users need to handle portable components manually.

=== Example: Buttons

First, define a portable component in `src/PortableComponents/Button/Model.elm`, where the "button" has its own special `Data`, `Target`, and `Msg`. Now we want to make it into a user component held by a layer.

*Note.* There is no CLI command for users to directly generate a portable component.

#grid(columns: (1fr, 1fr),
  [
    #set align(center)
```elm
type Msg
    = InitData (Maybe Data)
    | Pressed
```
  ], [
    #set align(center)
```elm
type Target
    = Other
    | Me
```
  ]
)


On this purpose, we create a function to transform "button" to a user component in `Scenes/Home/Components/Button.elm` with basics defined in `Scenes/Home/Components/ComponentBase.elm`. The `ComponentMsg` and `ComponentTarget` are defined as below:

#grid(columns: (1fr, 1fr),
  [
    #set align(center)
```elm
type ComponentMsg
    = ButtonInit Button.Data
    | ButtonPressed String
    | NullComponentMsg
```
  ], [
    #set align(center)
```elm
type alias ComponentTarget =
    String
```
  ]
)

Then, in `Scenes/Home/Components/Button.elm`, we define the component generator by:

```elm
component : Int -> ComponentTarget -> PortableComponentStorage SceneCommonData UserData ComponentTarget ComponentMsg BaseData SceneMsg
component zindex gtar =
    let
        targetCodec : PortableTarCodec Button.Target ComponentTarget
        targetCodec =
            { encode = \_ -> Button.Other
            , decode = \_ -> gtar
            }

        msgCodec : PortableMsgCodec Button.Msg ComponentMsg
        msgCodec =
            { encode =
                \msg ->
                    case msg of
                        ButtonInit data ->
                            Button.InitData (Just data)

                        _ ->
                            Button.InitData Nothing
            , decode =
                \msg ->
                    case msg of
                        Button.InitData _ ->
                            NullComponentMsg

                        Button.Pressed ->
                            ButtonPressed gtar
            }
    in
    genPortableComponent Button.componentcon targetCodec msgCodec () zindex
```

Note that `gtar` is used to initialize the component, and `zindex` is the z-index property of the created component.

Now the portable component `button` can be used as normal user components in the layer.

=== Use with User Components

To validate that the portable component type has been successfully transformed into user components, users can add a sample component.

Use the component in User Component part and simply modify it. To make things easy, remove the id and the update logic. 

When click the button, the rectangle is expected to turn yellow. But the logic of changing color doesn't need to be added in the `update` function of button:
```elm
MouseDown 0 pos ->
    if judgeMouseRect pos data.pos data.size then
        ( data, [ Other ( OtherC, Pressed ) ], ( env, True ) )
    
    else
        ( data, [], ( env, False ) )
```
Instead, it should be added in the codec in `Components/Button.elm`, where the translator is stored. More specifically, to make the the buttons more general, users can determine what message they should pass when initialize every single one of them. 
```elm
component : Int -> ComponentTarget -> ComponentMsg -> PortableComponentStorage SceneCommonData UserData ComponentTarget ComponentMsg BaseData SceneMsg
component zindex gtar gmsg =
    let
        ...
        msgCodec : PortableMsgCodec Button.Msg ComponentMsg
        msgCodec =
            ...
            decode = 
                ...
                Button.Pressed ->
                    gmsg
            ...
    in
    genPortableComponent Button.componentcon targetCodec msgCodec () zindex
```
Then initialize two buttons and a rectangle in one list in layer:
```elm
init : LayerInit SceneCommonData UserData LayerMsg Data
init env initMsg =
    Data
        [ Button.component 1 "Rect" (RectMsg yellow) (ButtonInit <| ButtonConfig.Data ( 0, 0 ) ( 100, 100 ) "Button 1") env
        , Button.component 1 "Rect" (RectMsg orange) (ButtonInit <| ButtonConfig.Data ( 300, 300 ) ( 100, 100 ) "Button 2") env
        , Rect.component ( RectInit <| RectMsg.Init 200 500 200 200 red ) env
        ]
```
Now the the requirement is simply implement since every specific button message `Other OtherC Pressed` will be decode as `Other ( "Rect", RectMsg yellow )`.

Find the detailed example #link("https://github.com/linsyking/messenger-examples/tree/main/portable-components")[here].

Users can even make different translators for the same portable component type to implement different usages. And the same type of portable component can be used in different scenes by setting translators for every scene. See more usages about portable components in @componentgroup.