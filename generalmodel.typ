#pagebreak()

= General Model

In previous sections, we discussed the general model. Its definitions are as follows:

```elm
type AbstractGeneralModel env event tar msg ren bdata sommsg
    = Roll
        { update : env -> event -> ( AbstractGeneralModel env event tar msg ren bdata sommsg, List (Msg tar msg sommsg), ( env, Bool ) )
        , updaterec : env -> msg -> ( AbstractGeneralModel env event tar msg ren bdata sommsg, List (Msg tar msg sommsg), env )
        , view : env -> ren
        , matcher : tar -> Bool
        , baseData : bdata
        }

type alias ConcreteGeneralModel data env event tar msg ren bdata sommsg =
    { init : env -> msg -> ( data, bdata )
    , update : env -> event -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), ( env, Bool ) )
    , updaterec : env -> msg -> data -> bdata -> ( ( data, bdata ), List (Msg tar msg sommsg), env )
    , view : env -> data -> bdata -> ren
    , matcher : data -> bdata -> tar -> Bool
    }
```

*Note.* Scenes are similar to layers and components, but have some differences as well. So the core does not define scene by `GeneralModel`.

In brief, `AbstractGeneralModel` is a model that can update itself and generate the view but hiding the data to the user.

When the model updates itself, it will be fed an event (a _user event_, used in `update`) or a message from other object (used in `updaterec`) and it will generate a list of new messages with targets. The target can be either the same type of object or the higher level object. For example, a component can send messages to another component in the same scene and to its parent layer; a layer can send messages to another layer and to its parent scene.

If the input is an event, the model can choose to _block_ it from sending to the next object. To prevent getting wrong messages, model use _matcher_ to identify itself.

The model also has a `baseData` field so that users can get some specific type of data outside the model. This is used in components.

A `ConcreteGeneralModel` can be considered as the _initialization data_ of its corresponding `AbstractGeneralModel`. Specific logic for every part of the `AbstractGeneralModel` should be implemented in `ConcreteGeneralModel` "concretely". That is, to generate a `AbstractGeneralModel`, users have to set a `ConcreteGeneralModel` first, then `abstract` it.

The `abstract` function mainly takes use of the _delayed evaluation_ to implement.

First, consider a simple example.

```elm
type Abstract
    = Roll (() -> Abstract)

type alias Concrete a =
    { init : a, update : a -> a }

abstract : Concrete a -> Abstract
abstract con =
    let
        abstractRec : a -> Abstract
        abstractRec a =
            let
                func : () -> Abstract
                func () =
                    abstractRec <| con.update a
            in
            Roll func
    in
    abstractRec con.init
```

`Abstract` hides the data it is updating and only leaves the interface for users to use. Thus, `Abstarct` with different inner data types can have the same type. The `update` function is like a _virtual function_ in OOP.

Next, let's examine how a concrete `view` is transformed into an abstract `view` for a more advanced example.

```elm
abstract : ConcreteGeneralModel data env event tar msg ren bdata sommsg -> msg -> env -> AbstractGeneralModel env event tar msg ren bdata sommsg
abstract conmodel initMsg initEnv =
    let
        abstractRec : data -> bdata -> AbstractGeneralModel env event tar msg ren bdata sommsg
        abstractRec data base =
            let
                ...
                views : env -> ren
                views env =
                    conmodel.view env data base
            in
            Roll
                { update = updates
                , updaterec = updaterecs
                , view = views
                , matcher = matchers
                , baseData = baseDatas
                }
        ( init_d, init_bd ) =
            conmodel.init initEnv initMsg
    in
    abstractRec init_d init_bd
```

After understanding the relationship between the concrete model and the abstract model, `Messenger.Recursion.updateObjects` can be used to update all objects recursively.

```elm
updateObjects : env -> event -> List (AbstractGeneralModel env event tar msg ren bdata sommsg) -> ( List (AbstractGeneralModel env event tar msg ren bdata sommsg), List (MsgBase msg sommsg), ( env, Bool ) )
```

Note that the output messages of `updateObjects` don't include the targets because the target of those messages are the parent object. If the result has messages that needs to be sent to a same level object, the recursion won't stop.

If users want to only send a specific message(s) to a specific object(s), they may use `updateObjectsWithTarget`:

```elm
updateObjectsWithTarget : env -> List ( tar, msg ) -> List (AbstractGeneralModel env event tar msg ren bdata sommsg) -> ( List (AbstractGeneralModel env event tar msg ren bdata sommsg), List (MsgBase msg sommsg), env )
```
