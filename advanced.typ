#import "@preview/fletcher:0.4.5" as fletcher: diagram, node, edge
#pagebreak()
= Advanced Usage

== LocalStorage <localstorage>

#link("https://developer.mozilla.org/en-US/docs/Web/API/Window/localStorage")[Local storage] is a mechanism to store data in the browser.
It allows the game to save data locally.

In Messenger, local storage content is defined by a `String`. When users need to save something to local storage, they need to first serialize it (for example, use `Json`).

Users can read or write to local storage by editing `globalData.userdata` and the data type in local storage is defined in `Lib/UserData.elm`. However, not all things in `UserData` are needed to store to local storage.

Users will need to implement `initGlobalData` and `saveGlobalData` functions. They act as a decoder and decoder for global data.

`initGlobalData` is called when the game starts.
Its type is:

```elm
initGlobalData : String -> UserViewGlobalData UserData
```

The string it needs is the real local storage data. Users will use the local storage data to initialize a global data. The `UserViewGlobalData`

`saveGlobalData` is called when user wants to save the global data (emitted by a `SOMSaveGlobalData` message). Users may encode some part of global data.

== Advanced Component Management

Components are the most useful and flexible objects in Messenger. They can be very powerful if used in a correct way.

=== Component Group <componentgroup>

Users may use the following command when creating a component to configure the directory the component is created in:

```bash
# Use -cd Or --cdir
messenger component Home Comp1 -cd CSet1
```

This will create a `Scenes/Home/CSet1/Comp1` directory and corresponding component files. The default value of `--cdir` is `Components`.

Grouping components can be helpful because they may have different types of `BaseData`, `Msg` and `Target`. So every group will have a `ComponentBase.elm` and it can be set individually, which means different groups of concrete component type will be abstract into different abstract type. In this way, the component configurations can be organized more methodically, instead of putting everything in one type. The cons is that it is inconvenient to communicate between different groups of components.

Therefore, this feature should be used only after careful consideration. In other words, use it only when the component type in one group hardly need to communicate with other groups of components.

Portable components can be used in an advanced way through this feature. Users can translate the same concrete type into different abstract type for different groups (different from using multiple translators in one group), so that their usages can be managed more clearly. Moreover, some portable components can be set in one group without other user components if needed. Then users can easily manage some portable components that is weakly related to the main game logic such as decorating elements.

=== Sub-component and Component Composition

Users can add components in the component data, this might sounds amazing but reasonable since every data type can be put into a component, including scenes and layers (interesting but useless). Adding components, named as sub-components, could be useful in some situation.

Imagine a situation that in an adventure game, the main character cast magic to fight against enemies. Since the magic system is the core mechanics in this game, it is designed in a complex way: different magics are corresponding to different spells; the magic system needs level value and MP value to judge if a magic can be cast or not; the magic system stores all the magics that the main character has learned.

Of course it can be implement in the character component, combine with other features such as movement, level up, weapons and so on. But this is obviously not a good choice, especially when the magic system is such a complex mechanics.

A better way is to abstract the magic system into a component. For example, the magics have been learned can be stored in `data`, the logic of casting a magic can be implemented in `updaterec` function, and the visual effects of different magic are implemented in `view` function. Since the component for magic system do not need to communicate with other components, it can be put into a separate group.

*Note.* The main character here should not be treated as the same layer component but a parent object when judging the communication objects of the magic system.

Then a magic system component can be added to the data of main character and in the main logic of main character users don't need to care about the implementation of magic system anymore. In other words, the magic system provides some interfaces to outside in this way.

After make a sub-component in this way, users can do more than the previous things! What if some boss in the game has the ability to cast magic? This feature can be easily implemented by adding a magic system component to boss component (maybe a composition of enemy and special features).

This is what is called #link("https://en.wikipedia.org/wiki/Emergent_gameplay")[Emergent gameplay]. Using component composition strategy can somehow do it easy at the code level.

*Note.* Users don't have to use the component type for compositing features. A simple timer, for instance, can be implemented by just `basedata` and `update`. But component type is more general for most of the situations, and it is easier since many tools have been prepared for a component.

*Note.* Do not abstract every simple feature into a component or custom type because you don't need too many portable features! Too many sub-components are chaotic and unmanageable. So use this strategy after thoughtful consideration.

=== Five-Step Updating to Manage Components

Five-Step updating strategy is used to simplify the update logic of a parent object with components (usually is layer). When developing in Messenger, managing the components could be a complex issue, especially when there are several component groups to deal with.

Generally, the `update` function in a parent object with components can be divided into five steps:

+ Update basic data (remove dead components, etc.)
  ```elm
  type alias BasicUpdater data cdata userdata tar msg scenemsg =
      Env cdata userdata -> UserEvent -> data -> ( data, List (MMsg tar msg scenemsg userdata), ( Env cdata userdata, Bool ) )
  ```
+ Update component groups by using `updateComponents`
+ Determine the messages that need to be sent to components and distribute them (collisions, etc.)
  ```elm
  type alias Distributor data cdata userdata tar msg scenemsg cmsgpacker =
      Env cdata userdata -> UserEvent -> data -> ( data, ( List (Msg tar msg scenemsg userdata), cmsgpacker ), Env cdata userdata )
  ```
  where `cmsgpacker` type is a helper type for users to send different type of messages to different component groups. Generally, it should be a record with a similar structure to `data`:
  ```elm
  type alias ComponentMsgPacker =
      { components1: List ( Components1Target, Components1Msg )
      , components2: List ( Components2Target, Components2Msg )
      ...
      }
  ```
  For the objects only need to manage one list of components, the `cmsgpacker` type could be:
  ```elm
  type alias ComponentMsgPacker =
      List ( ComponentTarget, ComponentMsg )
  ```
  Distributor type can also be useful in `updaterec` function.
+ Update the components with the `cmsgpacker` in step 3 using `updateComponentsWithTarget`. If there are multiple `cmsgpacker` results, they need to be combined together first.
+ Handle all the component messages generated from the previous steps.

Here is an example of a layer with two lists of components in different component groups:

```elm
update : LayerUpdate SceneCommonData UserData Target LayerMsg SceneMsg Data
update env evt data =
    let
        --- Step 1
        ( newData1, newlMsg1, ( newEnv1, newBlock1 ) ) =
            updateBasic env evt data

        --- Step 2
        ( newAComps2, newAcMsg2, ( newEnv2_1, newBlock2_1 ) ) =
            updateComponentsWithBlock newEnv1 evt newBlock1 newData1.acomponents

        ( newBComps2, newBcMsg2, ( newEnv2_2, newBlock2_2 ) ) =
            updateComponentsWithBlock newEnv2_1 evt newBlock2_1 newData1.bcomponents

        --- Step 3
        ( newData3, ( newlMsg3, compMsgs ), newEnv3 ) =
            distributeComponentMsgs newEnv2_2 evt { newData1 | acomponents = newAComps2, bcomponents = newBComp2 }

        --- Step 4
        ( newAComps4, newAcMsg4, newEnv4_1 ) =
            updateComponentsWithTarget newEnv3 compMsgs.acomponents newData3.acomponents

        ( newBComp4, newBcMsg4, newEnv4_2 ) =
            updateComponentsWithTarget newEnv4_1 compMsgs.bcomponents newData3.bcomponents

        --- Step 5
        ( newData5_1, newlMsg5_1, newEnv5_1 ) =
            handleComponentMsgs newEnv4_2 (newAcMsg2 ++ newAcMsg4) { newData3 | acomponents = newAComps4, bcomponents = newBComp4 } (newlMsg1 ++ newlMsg3) handlePComponentMsg

        ( newData5_2, newlMsg5_2, newEnv5_2 ) =
            handleComponentMsgs newEnv5_1 (newBcMsg2 ++ newBcMsg4) newData5_1 newlMsg5_1 handleUComponentMsg
    in
    ( newData5_2, (newlMsg5_2, ( newEnv5_2, newBlock2_2 ) )
```
\ 
\ 

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((0.8, 0.3), [`otherData`], corner-radius: 0pt),
    node((0, 0), [`acomponents`], corner-radius: 0pt),
    node((0, 0.6), [`bcomponents`], corner-radius: 0pt),
    node(enclose: ((0.8, 0.3), (0, 0),(0, 0.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <init>),
    node((0.8, -0.2), text(fill: blue)[`Data`], stroke: none),
    node((0.8, 2.3), [`otherData'`], corner-radius: 0pt),
    node((0, 2), [`acomponents'`], corner-radius: 0pt),
    node((0, 2.6), [`bcomponents'`], corner-radius: 0pt),
    node(enclose: ((0.8, 2.3), (0, 2),(0, 2.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step1>),
    node((0.8, 1.8), text(fill: blue)[`Data1`], stroke: none),
    edge(<init>, <step1>, `BasicUpdater`, "->", label-side: center),
    node((0.8, 4.3), [`otherData'`], corner-radius: 0pt),
    node((0, 4), [`acomponents2`], corner-radius: 0pt),
    node((0, 4.6), [`bcomponents'`], corner-radius: 0pt),
    node(enclose: ((0.8, 4.3), (0, 4),(0, 4.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step1.5>),
    node((0.8, 3.8), text(fill: blue)[`Data1'`], stroke: none),
    edge(<step1>, <step1.5>, `updateComponentsWithBlock a`, "->", label-side: center),
    node((0.8, 6.3), [`otherData'`], corner-radius: 0pt),
    node((0, 6), [`acomponents2`], corner-radius: 0pt),
    node((0, 6.6), [`bcomponents2`], corner-radius: 0pt),
    node(enclose: ((0.8, 6.3), (0, 6),(0, 6.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step2>),
    node((0.8, 5.8), text(fill: blue)[`Data1''`], stroke: none),
    edge(<step1.5>, <step2>, `updateComponentsWithBlock b`, "->", label-side: center),
    node((0.8, 8.3), [`otherData''`], corner-radius: 0pt),
    node((0, 8), [`acomponents2'`], corner-radius: 0pt),
    node((0, 8.6), [`bcomponents2'`], corner-radius: 0pt),
    node(enclose: ((0.8, 8.3), (0, 8),(0, 8.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step3>),
    node((0.8, 7.8), text(fill: blue)[`Data3`], stroke: none),
    edge(<step2>, <step3>, `Distributor`, "->", label-side: center),
    node((2.3, 1.3), [`LayerMsg1`], corner-radius: 0pt),
    edge((0.8, 1.3), (2.3, 1.3), "->"),
    node((-1.2, 3.3), [`AcMsg2`], corner-radius: 0pt),
    edge((-0.3, 3.3), (-1.2, 3.3), "->"),
    node((-2.7, 5.3), [`BcMsg2`], corner-radius: 0pt),
    edge((-0.3, 5.3), (-2.7, 5.3), "->"),
    node((2.3, 7.3), [`LayerMsg3`], corner-radius: 0pt),
    edge((0.8, 7.3), (2.3, 7.3), "->"),
    // node((-1.2, 7.3), [`toAcMsg3`], corner-radius: 0pt),
    // edge((0, 7.3), (-1.2, 7.3), "->"),
    // node((-2.7, 7.3), [`toBcMsg3`], corner-radius: 0pt),
    // edge((-1.2, 7.3), (-2.7, 7.3), "-"),
    node(enclose: ((2.3, 0.3), (2.3, 7.3)), stroke: (paint: red, dash: "dashed"), inset: 8pt),    
    node((2.3, 0.3), text(fill: red)[Layer Msg], stroke: none),
    node(enclose: ((-1.2, 2.3), (-1.2, 9.3)), stroke: (paint: green, dash: "dashed"), inset: 8pt),    
    node((-1.2, 2.3), text(fill: green)[A Msg], stroke: none),
    node(enclose: ((-2.7, 4.3), (-2.7, 9.3)), stroke: (paint: purple, dash: "dashed"), inset: 8pt),    
    node((-2.7, 4.3), text(fill: purple)[B Msg], stroke: none),
    edge(<step3>, (0.4, 9.5), "->"),
    edge((2.3, 7.8),(2.3, 9.5),stroke: (paint: red, dash: "dashed"), "->"),
    edge((0, 7.3), (-0.7, 7.3), (-0.7, 9.5), "->")
  )
]

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    edge((-0.7, 0.0), (-0.7, 0.3)),
    edge((-0.75, 0.3), (0.3, 0.3), `toAcMsg`, "->"),
    edge((-0.7, 2.3), (-0.7, 3.6)),
    edge((-0.7, 3.6), (0.3, 3.6), `toBcMsg`, "->"),
    node((0.8, 2.3), [`otherData''`], corner-radius: 0pt),
    node((0, 2), [`acomponents4`], corner-radius: 0pt),
    node((0, 2.6), [`bcomponents2'`], corner-radius: 0pt),
    node(enclose: ((0.8, 2.3), (0, 2),(0, 2.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step3.5>),
    node((0.8, 1.8), text(fill: blue)[`Data3'`], stroke: none),
    edge((0.4, 0), <step3.5>, `updateComponentsWithTarget a`,"->", label-side: center),
    node((0.8, 5.3), [`otherData''`], corner-radius: 0pt),
    node((0, 5), [`acomponents4`], corner-radius: 0pt),
    node((0, 5.6), [`bcomponents4`], corner-radius: 0pt),
    node(enclose: ((0.8, 5.3), (0, 5),(0, 5.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step4>),
    node((0.8, 4.8), text(fill: blue)[`Data3''`], stroke: none),
    edge(<step3.5>, <step4>, `updateComponentsWithTarget b`,"->", label-side: center),
    node((0.8, 8.3), [`otherData'''`], corner-radius: 0pt),
    node((0, 8), [`acomponents4'`], corner-radius: 0pt),
    node((0, 8.6), [`bcomponents4'`], corner-radius: 0pt),
    node(enclose: ((0.8, 8.3), (0, 8),(0, 8.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step5_1>),
    node((0.8, 7.8), text(fill: blue)[`Data5_1`], stroke: none),
    edge(<step4>, <step5_1>, `handleComponentMsgs a`,"->", label-side: center),
    node((0.8, 11.3), [`otherData''''`], corner-radius: 0pt),
    node((0, 11), [`acomponents4''`], corner-radius: 0pt),
    node((0, 11.6), [`bcomponents4''`], corner-radius: 0pt),
    node(enclose: ((0.8, 11.3), (0, 11),(0, 11.6) ), stroke: (paint: blue), corner-radius: 6pt, inset: 8pt, name: <step5_2>),
    node((0.8, 10.8), text(fill: blue)[`Data5_2`], stroke: none),
    edge(<step5_1>, <step5_2>, `handleComponentMsgs b`,"->", label-side: center),
    node((-1.2, 1.3), [`AcMsg4`], corner-radius: 0pt),
    edge((0.3, 1.3), (-1.2, 1.3), "->"),
    node((-2.7, 4.3), [`BcMsg4`], corner-radius: 0pt),
    edge((0.3, 4.3), (-2.7, 4.3), "->"),
    node((2.3, 7.3), [`LayerMsg5_1`], corner-radius: 0pt),
    edge((0.5, 7.3), (2.3, 7.3), "->"),
    edge((2.3, 7.3), (2.3, 9.3), (0.6, 9.3), stroke: (paint: red, dash: "dashed"), "->"),
    node((2.3, 10.3), [`LayerMsg5_2`], corner-radius: 0pt),
    edge((0.5, 10.3), (2.3, 10.3), "->"),
    edge((2.3, 0),(2.3, 6.3), (0.6, 6.3),stroke: (paint: red, dash: "dashed"), "->"),
    node(enclose: ((-1.2, 0), (-1.2, 1.3)), stroke: (paint: green, dash: "dashed"), inset: 8pt),    
    node((-1.2, 0), text(fill: green)[A Msg], stroke: none),
    edge((-1.2, 1.8),(-1.2, 6.3), (0.2, 6.3),stroke: (paint: green, dash: "dashed"), "->"),
    node(enclose: ((-2.7, 0), (-2.7, 4.3)), stroke: (paint: purple, dash: "dashed"), inset: 8pt),    
    node((-2.7, 0), text(fill: purple)[B Msg], stroke: none),
    edge((-2.7, 4.8),(-2.7, 9.3), (0.2, 9.3),stroke: (paint: purple, dash: "dashed"), "->"),
    node(enclose: ((-1, 12), (2.3, 10.3)), stroke: (paint: blue, dash: "dashed"), inset: 8pt),
    node((2, 11.8), text(fill: blue)[Result], stroke: none)
  )
]

== Initial Asset Loading Scene

User may want to have an asset loading scene just like what Reweave does.

When Messenger is loading assets, `update` of the initial scene will not be called. All the user input and events are ignored. However, `view` will be called. `globalTime` and `currentTimeStamp` will be updated but `sceneStartTime` will not be updated.

Moreover, users can get the number of loaded assets by using the `loadedResourceNum` function. Then you can compare it with `resourceNum resource`.

An example:

```elm
startText : GlobalData UserData -> Renderable
startText gd =
    let
        loaded =
            loadedResourceNum gd

        total =
            resourceNum resources

        progress =
            String.slice 0 4 <| String.fromFloat (toFloat loaded / toFloat total * 100)

        text =
            if loaded /= total then
                "Loading... " ++ progress ++ "%"

            else
                "Click to start"
    in
    group [ alpha (0.7 + sin (toFloat gd.globalTime / 10) / 3) ]
        [ renderTextWithColorCenter gd 60 text "Arial" Color.black ( 960, 900 )
        ]
```

The full example is in #link("https://github.com/linsyking/messenger-examples/tree/main/spritesheet")[messenger examples].

== Global Component <gc>

Although portable components and user components can be used to handle some logic, they are scene-specific, i.e. they cannot run across multiple scenes.

We need a way to run components inside core that could manipulate core runtime data (like the running scene). _Global component_ is a general model that is defined as:

```elm
type alias GCCommonData userdata scenemsg =
    MAbstractScene userdata scenemsg

type alias GCBaseData =
    { dead : Bool
    , postProcessor : Renderable -> Renderable
    }

type alias GCMsg =
    Json.Decode.Value

type alias GCTarget =
    String

type alias ConcreteGlobalComponent data userdata scenemsg =
    { init : GlobalComponentInit userdata scenemsg data
    , update : GlobalComponentUpdate userdata scenemsg data
    , updaterec : GlobalComponentUpdateRec userdata scenemsg data
    , view : GlobalComponentView userdata scenemsg data
    , id : GCTarget
    }

type alias AbstractGlobalComponent userdata scenemsg =
    MAbstractGeneralModel (GCCommonData userdata scenemsg) userdata GCTarget GCMsg GCBaseData scenemsg
```

Differing from user components and portable components, global components have fixed `msg` and `target` type which is `Value` and `String`. The common data is the running scene, while the base data is a record of `dead` and `postProcessor`. Global components could communicate with each other via the limited `Value` message. However, you can use whatever data type you want to design the data of the global component and initialize it with any data.

You may load the global components either at the beginning of the game or during runtime via a `SOMMsg`. To load a global component at the beginning, edit `GlobolComponents.elm`:

```elm
allGlobalComopnents : List (GlobalComponentStorage UserData SceneMsg)
allGlobalComopnents =
    [ FPS.genGC (FPS.InitOption 20) Nothing
    ]
```

To load, unload, or communicate with global components at runtime, users could use these two `SOMMsg`s:

```elm
type SceneOutputMsg scenemsg userdata
    ...
    | SOMLoadGC (GlobalComponentStorage userdata scenemsg)
    | SOMUnloadGC GCTarget
    | SOMCallGC (List ( GCTarget, GCMsg ))
```

Global components will update before the scene and will render after the scene. They can remove themself by changing `dead` to `True` in base data. Besides, global components may post-process the `Renderable` result generated by the scene by adding a `PostProcessor: Renderable -> Renderable` in `postProcessor` field of the base data.

There are some global components in the `messenger-extra` library, including `FPS` and `Transition`. Users could read the source code of those two global components to understand how game components work.

=== FPS

This is a global component to show the Frames Per Second (FPS) value on the screen. It stores last 10 values of `delta` every `Tick` event and calculate the average to determine the FPS. To use `FPS`, add it in `GlobalComponents.elm`.

Its generator is:

```elm
genGC : InitOption -> Maybe GCTarget -> GlobalComponentStorage userdata scenemsg
```

`InitOption` is some rendering options. `Maybe GCTarget` is the name of the component. Leave `Nothing` to use the default `fps` name.

=== Transition

First, let's take a look at the concepts of transition.

Transition has "two stages":

1.  From the old scene to the transition scene
2.  From the transition scene to the new scene

It is defined by:

```elm
type alias Transition =
    { currentTransition : Int
    , outT : Int
    , inT : Int
    , outTrans : SingleTrans
    , inTrans : SingleTrans
    }
```

- `outT` is the time (in milliseconds) of the first stage
- `inT` is the time of the second stage
- `outTrans`: the `SingleTrans` of the first stage
- `inTrans`: the `SingleTrans` of the second stage

The real transition effect is implemented in `SingleTrans`:

```elm
type alias SingleTrans =
    InternalData -> Renderable -> Float -> Renderable
```

The `Renderable` argument is the `view` of next scene. the `Float` argument is current progress of the transition. It is a value from 0 to 1. 0 means the transition starts, and 1 means the transition ends.

To generate a full transition, use `genTransition`:

```elm
genTransition : ( SingleTrans, Duration ) -> ( SingleTrans, Duration ) -> Maybe TransitionOption -> Transition
```

`TransitionOption` is some option for transition. It is:

```elm
type alias TransitionOption =
    { mix : Bool
    }
```

`mix` indicates using the mixed transition mode. There are two transition modes. Mixed mode means during transition, two scenes are running at the same time. Sequential mode means the second scene will run after the frist scene finishes transition.

To actually use transition, you need to load the global component.

The `genGC` function requires an `InitOption` to initialize:

```elm
type alias InitOption scenemsg =
    { transition : Transition
    , scene : ( String, Maybe scenemsg )
    , filterSOM : Bool
    }
```

The `Transition` can be generated by `genTransition`, `scene` is the scene you want to make transition to, and `filterSOM` indicates whether some `SOMMsg`s should be blocked. If users choose to block `SOMMsg`, then `SOMChangeScene` and `SOMGCLoad` will not be filtered out.

Now let's take `Fade` transition as an example to explain how to use transition when changing the scene.

==== Black Screen Transition

Consider a common scenario when a scene A ends. User wants it to first fade out to black screen and then fade in the next scene B.

#align(center)[
  #diagram(
    node-stroke: 1pt,
    edge-stroke: 1pt,
    node((0, -.2), [A], corner-radius: 2pt),
    node((1.8, -.2), [Black Screen], corner-radius: 2pt),
    node((3.6, -.2), [B], corner-radius: 2pt),
    edge((0.2, -.2), (1.6, -.2), `Fade out`, "->"),
    edge((2, -.2), (3.4, -.2), `Fade in`, "->")
  )
]

Then we emit following `SOMMsg` in A's `update`:

```elm
SOMLoadGC (Transition.genGC (Transition.InitOption (genTransition ( fadeOutBlack, Duration.seconds 5 ) ( fadeInBlack, Duration.seconds 3 ) Nothing) ( "B", Nothing ) True) Nothing)
```

5 is the fade out time and 3 is the fade in time.

==== Direct Transition

Users may want to directly do transition to the next scene without the black screen.

This is possible by using `nullTransition` and `fadeInWithRenderable` functions.


#set align(center) 
#diagram(
      node-stroke: 1pt,
      edge-stroke: 1pt,
      node((0, -.2), [A], corner-radius: 2pt),
      node((3, -.2), [A], corner-radius: 2pt),
      node((5, -.2), [B], corner-radius: 2pt),
      edge((0.2, -.2), (3, -.2), `nullTransition`, "->"),
      edge((3, -.2), (5, -.2), `Fade in`, "->")
    )
#set align(left)

Since the second scene always exists behind the transition scene during the transition, if the original scene is transparent, the effect will be quite strange. To avoid this, add a white background to the scene (or layer):

```elm
view env data =
    group []
        [ coloredBackground Color.white env.globalData
        ...
        ]
```

Then emit this `SOMMsg`:

```elm
SOMLoadGC (Transition.genGC (Transition.InitOption (genTransition ( nullTransition, Duration.seconds 0 ) ( fadeInWithRenderable <| view env data, Duration.seconds 3 ) Nothing) ( "B", Nothing ) True) Nothing)
```

==== Mixed Transition

We can do transition in mixed mode:

```elm
SOMLoadGC (Transition.genGC (Transition.InitOption (genTransition ( fadeOutTransparent, Duration.seconds 1 ) ( fadeInTransparent, Duration.seconds 1 ) (Just <| TransitionOption True)) ( "B", Nothing ) True) Nothing)
```

The result is "A" is fading out while "B" is fading in. Two scenes are running at the same time. Scene "A" could still receive user events and send `SOMMsg`s.

The examples are #link("https://github.com/linsyking/messenger-core/blob/master/test/src/Scenes/Home2/Model.elm")[here].

==== Transition Implementing

Let's see how `fadeIn` and `fadeOut` is implemented in the core. Users can follow this to design their own transition.

```elm
fadeIn : Color -> SingleTrans ls
fadeIn color gd rd v =
    group []
        [ rd
        , shapes [ fill color, alpha (1 - v) ]
            [ rect gd ( 0, 0 ) ( gd.virtualWidth, gd.virtualHeight )
            ]
        ]

fadeOut : Color -> SingleTrans ls
fadeOut color gd rd v =
    group []
        [ rd
        , shapes [ fill color, alpha v ]
            [ rect gd ( 0, 0 ) ( gd.virtualWidth, gd.virtualHeight )
            ]
        ]
```

The common pattern is to put the next scene as the background and use an "alpha" value to control the transition scene.
