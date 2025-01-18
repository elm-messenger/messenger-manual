#import "@preview/fletcher:0.4.5" as fletcher: diagram, node, edge
#import fletcher.shapes: hexagon

= Introduction

There are several Elm packages like #link("https://package.elm-lang.org/packages/evancz/elm-playground/latest/")[elm-playground], which offer simple APIs to create a game. However, these packages have many limitations and are not suitable for creating complex games.

Messenger is a 2D game engine for Elm based on `elm-canvas`. It provides an architecture, a set of APIs, and many library functions to enable rapid game development. Additionally, Messenger is message-based and abstracts the concept of objects using the _co-inductive type_ technique.

Messenger has many cool features:

- *Coordinate System Support*

  The view-port and coordinate transformation functions are already implemented. Messenger is also adaptive to window size changes.

- *Separate User Code and Core Code*

  User code and core code are separated. Any side effects are controlled by the Messenger core. This helps debugging and decrease security concerns.

- *Basic Game Engine API Support*

  Messenger provides handy common game engine APIs. Including data storage, audio manager, sprite(sheet) manager, and so on. More features are still under development.
  
- *Modular Development*
  
  Every component, layer, and scene is a module, simplifying code management. The implementation is highly packaged, allowing focus on the specific logic of the needed functions. Messenger is designed for convenience and ease of use.

- *Highly Customizable*

  The data of each object can be freely defined. The target matching logic and message type are also customizable. Users can create their own object types using the provided General Model type.

- *Flexible Design*

  The engine can be used to varying degrees, with separate management of different tasks. Components can be organized flexibly using the provided functions, allowing classification of portable and non-portable components in any preferred way.

== Messenger Modules

There are several modules (subprojects) within the Messenger project. All the development of Messenger is on GitHub.

- #link("https://github.com/linsyking/Messenger")[Messenger CLI]. A handy CLI to create the game rapidly
- #link("https://github.com/linsyking/messenger-core")[Messenger-core]. Core Messenger library
- #link("https://github.com/linsyking/messenger-extra")[Messenger-extra]. Extra Messenger library with experimental features
- #link("https://github.com/linsyking/messenger-examples")[Messenger examples]. Some example projects
- #link("https://github.com/linsyking/messenger-templates")[Messenger templates]. Templates to use Messenger library. Used in the Messenger CLI

*Note.* This manual is compatible with core `13.0.0 <= v < 14.0.0`, templates 0.4.0 and CLI 0.4.0.

== Messenger Model

The concept of the Messenger model is summarized in the following diagram:

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    
    node((1, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((1+0.5, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((1+0.5, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((1, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node([Layer], enclose: ((1, 0), (1+0.5, 1)), corner-radius: 5pt, fill: teal.lighten(80%), stroke: 1pt + teal.darken(20%), name: <l1>),
    edge((1+0.5, 0), (1+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),
    edge((1, 0), (1+0.5, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((1, 1), (1, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((1, 1), (1+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),

    node((2, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((2+0.5, 0), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((2+0.5, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node((2, 1), width: 10pt, height: 10pt, shape: circle, fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%)),
    node([Layer], enclose: ((2, 0), (2+0.5, 1)), corner-radius: 5pt, fill: teal.lighten(80%), stroke: 1pt + teal.darken(20%), name: <l2>),
    edge((2+0.5, 0), (2+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),
    edge((2, 0), (2+0.5, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((2, 1), (2, 0), "->", stroke: 1pt + yellow.darken(20%)),
    edge((2, 1), (2+0.5, 1), "->", stroke: 1pt + yellow.darken(20%)),

    edge(<l1>, <l2>, "<->", stroke: 1pt + teal.darken(20%)),

    node(enclose: ((0.5,-1), (3,2)), corner-radius: 5pt, stroke: 1pt + blue, align(right + top, [Scene]), name:<scene>),
    node(enclose: ((0,-1.6),(3.5, 2.5)), align(right + top, [User Code]), stroke: (paint: blue, dash: "dashed")),

    let b1_height = 4.5,
    node((0.8, b1_height), [`Update`], corner-radius: 5pt,fill: red.lighten(60%), stroke: 1pt + red.darken(20%), name:<gcupdate>),
    node((2.3, b1_height), [`SceneResultRemap`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<srr>),
    node((3.5, b1_height), [`PostProcessor`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<pp>),

    node(enclose: (<gcupdate>, <srr>, <pp>, (0.3, b1_height - 1)), corner-radius: 5pt,  stroke: (paint: blue, dash: "dashed"), align(right + top, [Global Component]), name:<gccore>),
    edge(<scene>, <gccore>, "->", label: [`GCLoad/GCUnload`], label-side: center),

    let base_height = 5.8,

    node((1.2, base_height + 0.8), [`WorldEvent`], corner-radius: 5pt,fill: red.lighten(60%), stroke: 1pt + red.darken(20%), name:<world>),
    node((1.2, base_height + 1.6), [Elm Subscriptions], corner-radius: 5pt,fill: gray.lighten(60%), stroke: 1pt + gray.darken(20%), name:<sub>),
    node((0.4, base_height), [`GlobalData`], corner-radius: 5pt,fill: red.lighten(60%), stroke: 1pt + red.darken(20%), name:<gd>),
    node((1.2, base_height), [`UserEvent`], corner-radius: 5pt,fill: red.lighten(60%), stroke: 1pt + red.darken(20%), name:<user>),
    edge(<gcupdate>, <scene>, "->"),
    edge(<gd>, <gcupdate>, "->"),
    edge(<user>, <gcupdate>, "->"),
    edge(<sub>, <world>, "->"),
    edge(<world>, <user>, "->", label: "Filter"),
    node((2, base_height), [`GlobalData`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<ngd>),
    node((2.8, base_height), [`SceneOutputMsg`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<som>),
    node((2.8, base_height + 2), [`SOMHandler`], fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%), name:<somhandler>, shape: hexagon),
    node((3.8, base_height + 1), [`ViewHandler`], fill: yellow.lighten(60%), stroke: 1pt + yellow.darken(20%), name:<viewhandler>, shape: hexagon),
    node((3.8, base_height + 2), [Side Effects], corner-radius: 5pt, fill: gray.lighten(60%), stroke: 1pt + gray.darken(20%), name:<sideeff>),
    node((3.8, base_height), [`Renderable`], corner-radius: 5pt, fill: green.lighten(60%), stroke: 1pt + green.darken(20%), name:<render>),
    node((2, base_height + 1.5), [Core Data], corner-radius: 5pt, fill: orange.lighten(60%), stroke: 1pt + orange.darken(20%), name:<cdata>),
    edge(<world>, (2, base_height + 0.8), <cdata>, "-->"),
    edge(<somhandler>, (2.6, base_height + 1.5), <cdata>, "-->"),
    edge(<scene>, <srr>, "->"),
    edge(<srr>, <ngd>, "->"),
    edge(<srr>, <som>, "->"),
    edge(<ngd>, <somhandler>, "->"),
    edge(<som>, <somhandler>, "->"),
    edge(<render>, <viewhandler>, "->"),
    edge(<viewhandler>, <sideeff>, "->"),
    edge(<somhandler>, <sideeff>, "->"),
    edge(<scene>, <pp>, "->"),
    edge(<pp>, <render>, "->"),
    edge(<somhandler> ,(0.4,base_height+2), <gd>, "->"),
    node(enclose: ((0, 3),(4.8, base_height + 2.5)), align(right + top, [Core Code]), stroke: (paint: red, dash: "dashed")),
  )
]

Messenger provides two parts that users can use. The template _user code_ and the _core library code_. Users write code based on the template code and may use any functions in core library. In user code, users need to design the _logic_ of scenes, layers and components. _Logic_ includes the data structure it uses, the `update` function that updates the data when events occur, `view` function that renders the object. Messenger core will first transform world event into user event, then send that event to the scene with the current `globalData`. `globalData` is the data structure Messenger keeps between scenes and users can read and write. The user code will updates its own data and generate some `SceneOutputMessage`. Messenger core ("core" for short) will handle all that messages and updates `globalData`.

Messenger manages a game through three levels of objects (Users can create more levels if they want), listed from parents to children:

1. *Scenes*. The core maintains *one scene* at a time. Example: a single level of the game
2. *Layers*. One scene may have multiple layers. Example: the map of the game, and the character layer
3. *Components*. One layer may have multiple components. The small yellow circles in layers in the diagram are _components_. Example: bullets a character shoots

Parent levels can hold children levels, while children levels can send messages to parent levels. Messages can also be sent inside a level between different objects.

=== General Model

There are many similarities among scenes, layers and components. Messenger abstracts those object into one thing called _general model_. Scene is not a general model as it is special, but it is similar to a general model.

One of the most important features of Messenger is its _customizability_, i.e. users can define their own datatype for their general models. However, if the layers or components in one same scene are not the same type, how could the core update them?

The key is that although the data of general model differs, the _interface_ or actions on those objects are the same. For example, the `update` function is the same for all layers in one scene. As an analogy, an abstract class in OOP may define many _virtual functions_, and the derived class will implement those functions with their own data structure and implementation details. It's possible to convert a derived class instance to a base class instance and only use the base class interface. The type of base class is the same while the derived class may have different types.

In Messenger, the "derived class" is a "concrete object" that users need to implement and they can use whatever datatype they want. The "base class" is an "abstract object" that "upper-casts" the concrete object. Therefore, users are able to store different types of objects together in a list by casting them to abstract form.

However, unlike in OOP, it is impossible to down-cast an abstract object to a concrete object. Therefore, users should only upper-cast at the last moment.

Layers and components are defined as an alias of `AbstractGeneralModel`.
It is generated by a `ConcreteGeneralModel`, where users implement their logic. Its definition is this:

```elm
type alias ConcreteGeneralModel data env event tar msg ren bdata sommsg =
    { init : env -> msg -> ( data, bdata )
    , update : env -> event -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), ( env, Bool ) )
    , updaterec : env -> msg -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), env )
    , view : env -> data -> bdata -> ren
    , matcher : data -> bdata -> tar -> Bool
    }
```

`init` is the function to initialize the object.
`update` is the function to update the object when an event occur. `updaterec` is the function to update when other object send you a message. `view` is the function to generate `Renderable`. `matcher` is the function to identifies itself.

Type `env` is the _environment type_. It contains global data and common data, if any. `event` is the event type, `data` is the user defined datatype. `bdata` is the base data used in components (see @component). `ren` is the rendering type.

Messenger CLI will use templates to help you create scenes, layer and components.

=== Msg Model

The `Msg` type of Messenger is defined as below:

```elm
type Msg othertar msg sommsg
    = Parent (MsgBase msg sommsg)
    | Other (othertar, msg)
```
  where `MsgBase` is defined as
  ```elm
type MsgBase othermsg sommsg
    = SOMMsg sommsg
    | OtherMsg othermsg
  ```
  `SOMMsg`, or _Scene Output Message_, is a message that can directly interact with the core. For example, to play an audio, users can emit a `SOMPlayAudio` message, and the core will handle it.
#pagebreak()

    #diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node((0, -.2), [Component], corner-radius: 2pt),
      node((1.6, -.2), [Component], corner-radius: 2pt),
      node((.8, .8), [Layer], corner-radius: 2pt),
      edge((0, -.2), (1.8, -.2), `Other`, "->"),
      edge((0, -.2), (.8, .8), `Parent`, "->", bend: -30deg),
      edge((1.6, -.2), (.8, .8), `Parent`, "->", bend: 30deg)
    )
    #v(.5pt)
    #diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node((0, 0), [Component], corner-radius: 2pt),
      node((1.3, 0), [Layer], corner-radius: 2pt),
      node((1.3, .8), [Layer], corner-radius: 2pt),
      node((2.6, 0), [Scene], corner-radius: 2pt),
      node((2.6, .8), [Messenger], corner-radius: 2pt),
      edge((0, 0), (1.3, 0), `SOMMsg`, "->"),
      edge((1.3, 0), (2.6, 0), `SOMMsg`, "->"),
      edge((2.6, 0), (2.6, .8), `SOMMsg`, "->"),
      edge((0, 0), (1.3, .8), `OtherMsg`, "->", bend: -10deg)
    )

`SOMMsg` is passed to the core from Component $->$ Layer $->$ Scene. It's possible to block `SOMMsg` from a higher level. See @sommsg to learn more about `SOMMsg`s.

Users may need to handle `Parent` messages from components in a layer. Messenger provides a handy function `handleComponentMsgs` which is defined in `Messenger.Layer.Layer`, to help users handle those messages. Users need to provide a `MsgBase` handler, for example:

```elm
handleComponentMsg : Handler Data SceneCommonData UserData Target LayerMsg SceneMsg ComponentMsg
handleComponentMsg env compmsg data =
    case compmsg of
        SOMMsg som ->
            ( data, [ Parent <| SOMMsg som ], env )

        OtherMsg _ ->
            ( data, [], env )

        _ ->
            ( data, [], env )
```

Then users can combine it with `updateComponents` to define the `update` function in layers (provided in the Messenger template):

```elm
update : LayerUpdate SceneCommonData UserData LayerTarget LayerMsg SceneMsg Data
update env evt data =
    let
        ( comps1, msgs1, ( env1, block1 ) ) =
            updateComponents env evt data.components

        ( data1, msgs2, env2 ) =
            handleComponentMsgs env1 msgs1 { data | components = comps1 } [] handleComponentMsg
    in
    ( data1, msgs2, ( env2, block1 ) )
```

=== Example <example1>

A, B are two layers (or components) which are in the same scene (or layer) C. The logic of these objects are as follows:

- If A receives an integer $0 <= x <= 10$, then A will send $3x$ and $10-3x$ to B, and send $x$ to C.
- If B receives an integer $x$, then B will send $x-1$ to A.

Now at some time B sends $2$ to A, what will C finally receive?

Answer: 2, 5, 3, 8, 0, 9.
