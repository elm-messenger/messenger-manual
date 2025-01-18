#import "@preview/fletcher:0.4.4" as fletcher: diagram, node, edge
#pagebreak()
= Hello World in Messenger

== Installation

To create a simple game in Messenger, the first step is to install the Messenger CLI tool:

Messenger CLI is written in Python. You need to install `python>=3.7`. #link("https://pipx.pypa.io/stable/")[pipx] is a tool to manage python applications. It is recommended to use `pipx` instead of `pip` on Unix-based OS (including WSL).

```bash
pipx install -i https://pypi.python.org/simple elm-messenger>=0.4.0
# Or use pip on Windows:
pip install -i https://pypi.python.org/simple elm-messenger>=0.4.0
```

This tool assists in quickly building a project. To create a new project, use the following commands:


```bash
messenger init helloworld
# Or with custom repo:
messenger init helloworld -t <Repo URL>
# With custom branch:
messenger init helloworld -t <Repo URL> -b <Branch name>
```

Then, create a new scene and add a layer in that scene:

```bash
# Open our project directory
cd helloworld
# Create a new scene
messenger scene Home
# Create a new layer called MainLayer
messenger layer Home MainLayer
```

*Note:* If the scene name is not "Home", change the scene name in `initScene` in `MainConfig.elm` (which defines which scene to start), as it is set to "Home" by default.

*Hint:* It is fine to use lowercase letters like `home` and `mainLayer`. The Messenger CLI will automatically convert these to appropriate names.

*Note:* By default, a scene is a `LayeredScene`. To create a `RawScene` without any layers, add the `--raw` argument when creating a scene. Raw scene doesn't have `SceneBase.elm` when created. However, if users try to add a component or a layer to a raw scene, that file will automatically be created.

See @cli to learn more about Messenger CLI.

== Project Structure

```bash
./helloworld
├── assets # Store game assets in this folder
├── elm.json
├── index.html
├── Makefile
├── messenger.json
├── .messenger # Data used by Messenger, don’t modify this by hand!
├── public # JS, CSS and HTML files
└── src
    ├── Lib
    │   ├── Base.elm # Base types for many modules
    │   ├── Ports.elm
    │   ├── Resources.elm # Images to load
    │   └── UserData.elm # User global data
    ├── MainConfig.elm # Configurations for the game
    ├── Main.elm
    └── Scenes # Scene folder
        ├── AllScenes.elm # Stores all the scene data
        ├── GlobalComponents.elm # Stores all the global components
        └── Home # A scene called "Home"
            ├── MainLayer # A layer called "MainLayer" in Home
            │   ├── Model.elm # Layer definitions
            │   └── Init.elm # Init message type
            ├── Components # Scene components
            │   ├── Comp # A component called "Comp"
            │   │   ├── Model.elm
            │   │   └── Init.elm
            │   └── ComponentBase.elm
            ├── SceneBase.elm
            └── Model.elm
```

== Getting Started

First, determine the `UserData` and `SceneMsg`, which respectively represent the data that can be accessed or modified at any time and the message to be sent to the scene when switching scenes.

Next, prepare `userConfig` and a list containing all the scenes as inputs. The `userConfig` is a record that includes the basic configurations needed by the main function. This is automatically wrapped in `Main.elm`, so only the options in `MainConfig.elm` need to be modified.

An initial global data is also needed, but it is not necessary to provide the full global data. Instead, users only need to provide a subset that does not include any Messenger internal data.

Since this is a hello world project, only one scene is needed, so customizing `UserData` and `SceneMsg` can be skipped.

By default, Messenger does not add user layers to a scene automatically because it does not know how the layers will be initialized. It is a good practice to add layers to the scene immediately after creating them.

First, open `Scenes/Home/Model.elm` and import layer:

```elm
import Scenes.Home.MainLayer.Model as MainLayer
```

Second, add the layer to `init` function:

```elm
init env msg =
    ...
    , layers =
        [ MainLayer.layer NullLayerMsg envcd
        ]
```

Now open `Scenes/Home/MainLayer/Model.elm`. Change the `view` function:

```elm
import Messenger.Render.Text exposing (renderText)
...
view : LayerView SceneCommonData UserData Data
view env data =
    renderText env.globalData.internalData 40 "Hello World" "Arial" ( 900, 500 )
```

`LayerView` is a type sugar to represent the `view` type of layer.

```elm
type alias LayerView cdata userdata data =
    Env cdata userdata -> data -> Renderable
```

It will expands to

```elm
Env SceneCommonData UserData -> Data -> Renderable
```

`Env` is a type that represents the _environment_. Layers and components can not only update its own data, it can also view and update the environment (aka. _side effects_).

Its definition is:

```elm
type alias Env common userdata =
    { globalData : GlobalData userdata
    , commonData : common
    }
```

`GlobalData` is a type that Messenger keeps all the time. It has some key information Messenger needs to use like the screen size. Many Messenger library functions need global data as an argument.

`commonData` is the data shared among all the layers in a scene. It is defined in `Scenes/Home/SceneBase.elm:SceneCommonData`.

Let's take a closer look at `GlobalData`.

```elm
type alias GlobalData userdata =
    { internalData : InternalData
    , sceneStartTime : Int
    , globalStartTime : Int
    , globalStartFrame : Int
    , sceneStartFrame : Int
    , currentTimeStamp : Time.Posix
    , windowVisibility : Visibility
    , mousePos : ( Float, Float )
    , pressedMouseButtons : Set Int
    , pressedKeys : Set Int
    , extraHTML : Maybe (Html WorldEvent)
    , canvasAttributes : List (Html.Attribute WorldEvent)
    , volume : Float
    , userData : userdata
    , currentScene : String
    }
```

Global data won't be reset if users change the scene.

- `globalStartFrame` records the past frames number since the game started
- `globalStartTime` records the past time since the game started, in milliseconds
- `sceneStartFrame` records the past frames number since this scene started
- `sceneStartTime` records the past time since this scene started, in milliseconds
- `userdata` records the data that users set to save
- `extraHTML` is used to render extra HTML tags. Be careful to use this
- `windowVisibility` records whether users stay in this tab/window
- `pressedKeys` records the keycodes that are be pressed now
- `pressedMouseButtons` records the mouse buttons that are pressed now
- `volume` records the volume of the game
- `currentScene` records the current scene name
- `mousePos` records the mouse position, in virtual coordinate

*Note.* Since the `globalStartTime` and `sceneStartTime` are discrete, please use a range rather than a specific time point when judging the time. 

Now, run `make` to build the game, and use `elm reactor` or other static file hosting tools (If you use VS Code, you can try using the #link("https://marketplace.visualstudio.com/items?itemName=ritwickdey.LiveServer")[Live Server]), but *DO NOT* directly open the HTML file in the browser because assets won’t be loaded due to CORS.

We use coordinate `(900, 500)` to render the text instead of using HTML tags. This coordinate is not the real pixels on the screen, but the *virtual coordinate* in the game.

The virtual resolution is 1920 × 1080 by default, and the real resolution is determined by the browser window size. The virtual size is defined in `MainConfig.elm`, users may change it to whatever they like.

The `renderText` function wraps the `Canvas.text` which will transform virtual coordinate to the real coordinate. That’s why we also need to send `env.globalData` to that function.

== Order of Rendering <layers>

To understand layers and scenes better, let’s create another scene called "Game"
and add two layers called "A" and "B" in that scene.

```bash
# Create a new scene
messenger scene Game
# Create new layers
messenger layer Game A
messenger layer Game B
```

Now similarly, add these two layers to scene:

```elm
...
    , layers =
        [ A.layer NullLayerMsg envcd
        , B.layer NullLayerMsg envcd
        ]
```

Then draw a red rectangle on layer A and a blue rectangle on layer B at
the same position. See the result.

Layer B will be on the top of the layer A, which means A is rendered before B. 
The order is the same when using `Canvas.group`. The first element in a list will be rendered first and be at the bottom of the scene. Therefore, it is important to organize the order of layers correctly.

However, the order of updating is different from rendering. See @events.

== Message Passing

Recall the `update` function in `ConcreteGeneralModel`.

```elm
update : env -> event -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), ( env, Bool ) )
```

However, layers generally do not need `bdata`, so Messenger provides a `ConcreteLayer` type that hides `bdata` (making it a `()`):

```elm
type alias ConcreteLayer data cdata userdata tar msg scenemsg =
    { init : LayerInit cdata userdata msg data
    , update : LayerUpdate cdata userdata tar msg scenemsg data
    , updaterec : LayerUpdateRec cdata userdata tar msg scenemsg data
    , view : LayerView cdata userdata data
    , matcher : Matcher data tar
    }
```

Here `LayerUpdate` is defined by:

```elm
type alias LayerUpdate cdata userdata tar msg scenemsg data =
    Env cdata userdata -> WorldEvent -> data -> ( data, List (Msg tar msg (SceneOutputMsg scenemsg userdata)), ( Env cdata userdata, Bool ) )
```

`LayerUpdateRec` is defined by:

```elm
type alias LayerUpdateRec cdata userdata tar msg scenemsg data =
    Env cdata userdata -> msg -> data -> ( data, List (Msg tar msg (SceneOutputMsg scenemsg userdata)), Env cdata userdata )
```

Users can provide the `tar` and `msg` type in `Scenes/Home/SceneBase.elm`.

Now let's consider implementing the example mentioned in @example1. You can either start a new project or use the hello world project.

Create a scene with three layers:

```bash
messenger scene Recursion
messenger layer Recursion A
messenger layer Recursion B
messenger layer Recursion C
```

Add them to the scene (`Scenes/Recursion/Model.elm`):

```elm
import Scenes.Recursion.A.Model as A
import Scenes.Recursion.B.Model as B
import Scenes.Recursion.C.Model as C
...
    , layers =
        [ A.layer NullLayerMsg envcd
        , B.layer NullLayerMsg envcd
        , C.layer NullLayerMsg envcd
        ]
```

To send integers between layers, we need a `IntMsg`. So edit `Scenes/Recursion/SceneBase.elm`:

```elm
type LayerMsg
    = IntMsg Int
    | NullLayerMsg
```

For layer A, edit `Scenes/Recursion/A/Model.elm`:

```elm
updaterec env msg data =
    case msg of
        IntMsg x ->
            if 0 <= x && x < 10 then
                ( data, [ Other ( "B", IntMsg (3 * x) ), Other ( "B", IntMsg (10 - 3 * x) ), Other ( "C", IntMsg x ) ], env )

            else
                ( data, [], env )

        _ ->
            ( data, [], env )
```

For layer B, edit `Scenes/Recursion/B/Model.elm`:

```elm
update env evt data =
    if env.globalData.sceneStartFrame == 10 then
        ( data, [ Other ( "A", IntMsg 2 ) ], ( env, False ) )

    else
        ( data, [], ( env, False ) )
```

and

```elm
updaterec env msg data =
    case msg of
        IntMsg x ->
            ( data, [ Other ( "A", IntMsg (x - 1) ) ], env )

        _ ->
            ( data, [], env )
```

Finally, for layer C, edit `Scenes/Recursion/C/Model.elm`:

```elm
updaterec env msg data =
    case msg of
        IntMsg x ->
            let
                _ =
                    Debug.log "C received" x
            in
            ( data, [], env )

        _ ->
            ( data, [], env )
```

Now `make` and see the result!

== Initialization <init>

Users may want to initialize the layer or the scene with special data and may even with some environment information.

The data to initialize a layer or a scene must be defined in the layer messages or the scene messages. The layer will be initialized by that message.

We can investigate the `init` function in layer:

```elm
LayerInit SceneCommonData UserData LayerMsg Data
```

which expands to:

```elm
Env SceneCommonData UserData -> LayerMsg -> Data
```

So users can initialize a layer with the environment and a layer message.

Users can create an `Init.elm` file to store the initialization type for scenes, layers and components (`Init.elm` is automatically created for scene prototype). Messenger CLI provides an argument to add that file when creating a scene, a layer, or a component:

```bash
# Use --init or -i
messenger scene ... --init
messenger layer ... --init
messenger component ... --init
```

For example, if you run:

```bash
messenger scene Home --init
```

Then `Scenes/Home/Init.elm` will be created with empty `InitData`.

Users should know the dependency relationship clearly between all the modules, especially the `Init` modules, or they may run into cyclic dependency problems.

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((0, 0), [`Scenes.AllScenes`], corner-radius: 0pt),
    node((1, 1), [`Scenes.Level1.Model`], corner-radius: 0pt),
    node((0, 1), [`Scenes.Home.Model`], corner-radius: 0pt),
    node((0, 2), [`Lib.Base`], corner-radius: 0pt),
    node((1, 2), [...], corner-radius: 1pt),
    node((0, 3), [`Scenes.Home.Init`], corner-radius: 0pt),
    node((1, 3), [`SceneProtos.Game.Init`], corner-radius: 0pt),
    node((0, 4), [`Scenes.Home.SceneBase`], corner-radius: 0pt),
    node((1, 4), [...], corner-radius: 1pt),
    node((0, 6), [`Scenes.Home.Components.ComponentBase`], corner-radius: 0pt),
    node((0, 5), [`Scenes.Home.Layer1.Init`], corner-radius: 0pt),
    node((1, 5), [`Scenes.Home.Layer2.Init`], corner-radius: 0pt),
    node((-0.5, 7), [`Scenes.Home.Components.Enemy.Init`], corner-radius: 0pt),
    node((0.7, 7), [`Scenes.Home.Components.Player.Init`], corner-radius: 0pt),
    edge((0, 0), (0.9, 1), "->"),
    edge((0, 0), (0, 1), "->"),
    edge((1, 1), (1, 2), "->"),
    edge((0, 1), (0, 2), "->"),
    edge((0, 2), (0.9, 3), "->"),
    edge((1, 3), (1, 4), "->"),
    edge((0, 2), (0, 3), "->"),
    edge((0, 3), (0, 4), "->"),
    edge((0, 4), (0, 5), "->"),
    edge((0, 4), (0.9, 5), "->"),
    edge((0, 5), (0, 6), "->"),
    edge((0, 6), (-0.7, 7), "->"),
    edge((0, 6), (0.7, 7), "->"),
    node(enclose: ((-0.5, 0), (1, 1), (1, 0)), stroke: (paint: blue, dash: "dashed"), inset: 8pt),
    node((1, 0), text(fill: blue)[Models], stroke: none),
    node(enclose: ((-1, 2), (3, 7.5), (0, 2)), stroke: (paint: blue, dash: "dashed"), inset: 8pt),
    node((-1, 2), text(fill: blue)[Base and Init], stroke: none),
  )
]

In the above diagram, A $->$ B means A _may_ depend on B, and B *must not* depend on A.

As you can see, all the models can depend on all the `Base` and `Init`. So it's quite free to import any types you defined.

However, in the "Base and Init" zone, you should carefully handle the dependency. The rule is: *upper level may depend on lower levels*. *Never* use `Lib.Base` in any `Base` or `Init`. If necessary, use a type parameter and instantiate it in models (see the @sceneproto example).