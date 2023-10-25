module DependencyModel exposing (
    DepModel,
    DepMsg(..),
    updateDepModel,
    mkDepModel,
    mkDepModelView,
    mkTextQuestionView,
    Library(..),
    require,
    thenAsk
    )

{-| A style of interview in which we define the interview's ultimate requirements and use a library of functions that can satisfy those requirements. Those final requirements might themselves have their own requirements that have to be satisfied.



# The Model of the interview

@docs DepModel, DepMsg

@docs mkDepModel

@docs updateDepModel

# Questions to ask

@docs Library

@docs require, thenAsk

# Views

@docs mkDepModelView, mkTextQuestionView

-}

import Dict exposing (Dict)
import Inquisimin exposing (..)
import Html exposing (Html, div, input, button, text)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onClick, onInput)



{-| All DepModel interviews share this DepMsg type.

The DependencyModel style of interviews stores the interview's state in a 
`Dict Key (Question String)`. (and `Key` is just an alias to `String` for now). 

-}
type DepMsg = UpdateQuestion String String
         | SaveQuestion String String
         | StartOver
         | GoBack 


{-| The elm update function for the DepModel.

Receives DepMsg values and a DepModel and uses them to 
return a new DepModel. 
-}
updateDepModel : DepMsg -> DepModel -> DepModel
updateDepModel msg model = 
    case msg of
        UpdateQuestion k txt -> updateDepModelQ k txt model
        SaveQuestion k txt -> save k txt model
        StartOver -> empty model
        GoBack -> case previousQuestion model of 
            Nothing -> model
            Just (pqkey, pq) -> goback pqkey pq model

{-| Have an interview go back to the previous question.


-}
goback : Key -> Question String -> DepModel -> DepModel
goback keyToReturnTo qToReturnTo model =
    { state = unanswerQuestion keyToReturnTo qToReturnTo model.state
    , history = removeFromHistory keyToReturnTo model.history
    , requirements = keyToReturnTo :: model.requirements
    , originalRequirements = model.originalRequirements
    }


{-| Remove a key from the stored interview history 

-}
removeFromHistory : Key -> List Key -> List Key
removeFromHistory key history =
    case history of 
        [] -> []
        k::rest -> if k == key then rest else k::(removeFromHistory key rest)

{-| Reset a question to an unanswered state with a key `Key` in a state Dictionary. 

TODO this is only different from DictModel's version because we use a regular Dict here. 

-}
unanswerQuestion : Key -> Question String -> Dict Key (Question String) -> Dict Key (Question String)
unanswerQuestion key q state = 
    let 
        q_ = unanswer q
    in
        Dict.update key (\_ -> Just q_) state




{-| Update a question in the DepModel.
-}
updateDepModelQ : Key -> String -> DepModel -> DepModel
updateDepModelQ key txt model = { model | state = updateModelState key txt model.state }

{-| Update just the state part of the model in a DepModel
-}
updateModelState : Key -> String -> Dict Key (Question String) -> Dict Key (Question String)
updateModelState key txt model = Dict.update key (\_ -> Just <| updateQuestion txt (mkq alwaysValid)) model

{-| Save a question in a DepModel.

This requires setting a question as Answered
Adding this question to the history,
And removing it from the requirements.

-}
save : Key -> String -> DepModel -> DepModel
save key txt model = 
    { state = saveQuestion key txt model.state
    , history = recordQuestionToHistory key model.history
    , requirements = removeQuestionFromReqs key model.requirements
    , originalRequirements = model.originalRequirements
    }

{-| Set a question as Answsered in the DepModel's state. -}
saveQuestion : Key -> String -> Dict Key (Question String) -> Dict Key (Question String)
saveQuestion key txt state = 
    Dict.remove key state
    |> Dict.update key (\_ -> Just <| Answered txt txt (\t -> Valid t))


{-| Record a question to the history of the interview. -}
recordQuestionToHistory : Key -> List Key -> List Key
recordQuestionToHistory = (::) 

{-| Remove a question's key from the list of requirements -}
removeQuestionFromReqs : Key -> List Key -> List Key
removeQuestionFromReqs key requirements = 
    case requirements of 
        -- shouldn't ever happen, I think.
        [] -> []
        -- last should always == key
        [last] -> if last == key then [] else [last]
        last::more -> 
            if last == key 
                then more 
                else last :: (removeQuestionFromReqs key more)


{-| Empty the model.

-} 
empty : DepModel -> DepModel
empty {originalRequirements} = mkDepModel originalRequirements 


{-| Find the most-recently-asked question.

chatgpt rightly pointed out I could simplify this with Maybe.map2.
-}
previousQuestion : DepModel -> Maybe (String, (Question String))
previousQuestion model = 
    let 
        prevKey = case model.history of 
            [] -> Nothing
            -- things only get added to history when they're Answered.
            x::_ -> Just x
    in
        prevKey
        |> Maybe.andThen (\k -> Dict.get k model.state)
        |> Maybe.andThen (combinewith prevKey) 


combinewith : Maybe Key -> Question String -> Maybe (String, (Question String))
combinewith maybePrevKey q =
    maybePrevKey 
    |> Maybe.andThen (\k -> Just (k, q))


    


{-| keys for questionviews and for Questions in state.
-}
type alias Key = String

{-| The model for a dependency-oriented interview. -}
type alias DepModel = 
    { state : Dict Key (Question String) 
    , history : List Key
    , requirements : List Key
    , originalRequirements : List Key -- necessary to store, so we can start over.
    }

{-| Create a new DepenedencyModel from a list of required keys for the interview.

The order of this list of required keys will also determine the order of the interview, 
except if any item in the list has its own dependencies. A question's dependencies 
are asked before the question.

-}
mkDepModel : List Key -> DepModel
mkDepModel requirements =
    { state = Dict.empty
    , history = []
    , requirements = requirements
    , originalRequirements = requirements
    }


safeHead : List a -> Maybe a
safeHead xs = case xs of
    [] -> Nothing
    x::_ -> Just x

{-| Make a basic view function for a depmodel.

This function takes a library of functions and the current state of the model.

From the current state of the model, it either shows the question currently being edited, 
or else shows the next required question, 

-}
mkDepModelView : Library -> (DepModel -> Html DepMsg) -> DepModel -> Html DepMsg
mkDepModelView lib endView model = div []
    [ div [] [text "The interview"]
    , findQToAsk lib endView model
    ]

{-| Find the right question to ask. 

First, check the requirements. If there are none left, we're done!
If there are requirements, find the q to ask from the library.
If the q's ready to be asked, then we'll have a (QuestionView DepModel (Html DepMsg).

-}
findQToAsk : Library -> (DepModel -> Html DepMsg) -> DepModel ->  (Html DepMsg) 
findQToAsk lib endView model = 
    case model.requirements of
        [] -> endView model
        req::_ -> 
            case lookupInLibrary req lib of
                Nothing -> div [] [text <| "error. question for '" ++ req ++ "' not found"]
                Just q -> whatThis lib endView (q model) 


whatThis : Library -> (DepModel -> Html DepMsg) -> Interviewer DepModel (Html DepMsg) -> Html DepMsg
whatThis lib endView interviewer = case interviewer of
    Continue model -> findQToAsk lib endView model
    Ask html -> html 

        

{-| Defines a library of question that might get asked. 

The `Key`s in the Library identify how the assocated `QuestionView` will change the interview's 
state. A question that asks the user for a 'firstname' would have the `Key` of 'firstname'.

The interview uses this library to find questions that satisfy the `DependencyModel`'s requirements.

-}
type Library = Library (Dict Key (QuestionView DepModel (Html DepMsg)) )


{-| Try to find a question in the Library -}
lookupInLibrary : Key -> Library -> Maybe (QuestionView DepModel (Html DepMsg))
lookupInLibrary key (Library lib) = Dict.get key lib  

type Requirements 
    = Satisfied  DepModel
    | Unsatisfied DepModel (List Key)

{-| Require some keys to have been Answered before something else can be asked. 

-}
require : List Key -> DepModel -> Requirements
require requiredKeys model = 
    let 
        missingKeys = getMissing model requiredKeys 
    in 
        case missingKeys of 
            [] -> Satisfied model 
            missing -> Unsatisfied model missing

lookupInState : Key -> Dict String (Question String) -> Maybe (Question String)
lookupInState = Dict.get 

{-| Tells the interview to ask a 'QuestionView' if its `Requirements` are met. 

    q3 : QuestionView DepModel (Html DepMsg)
    q3 model = model
              |> require ["step1", "step2"]
              |> thenAsk (mkTextQuestionView "step3" "How many?")

-}
thenAsk : QuestionView DepModel (Html DepMsg) -> Requirements -> Interviewer DepModel (Html DepMsg)
thenAsk q req = case req of 
    Unsatisfied model needed -> Continue (pushToState model needed)
    Satisfied model -> q model




pushToState : DepModel -> List Key -> DepModel
pushToState model neededKeys = {model | requirements = neededKeys ++ model.requirements}

{-| Find any items in requiredKeys that haven't been Answered yet in the model.

    
-}
getMissing : DepModel -> List Key -> List Key
getMissing model required = List.foldl (checkMissing model.state) [] required


{-| Check if the question matching a certain key has been Answered in an interview's 
state.

-}
checkMissing : Dict String (Question String) -> Key -> List Key -> List Key
checkMissing state key acc = 
    case Dict.get key state of 
        Nothing -> key :: acc
        Just q -> case q of 
            Answered _ _ _ -> acc
            Unanswered _ _ _ -> key :: acc





{-| Helper to create a simple one-question view that 
asks a single question.

Takes a predictate Question that is Answered or Unanswered.
And Takes a label
-}
mkTextQuestionView : String -> String -> DepModel -> Interviewer DepModel (Html DepMsg)
mkTextQuestionView key label model = 
    let 
        -- find q in the model or make a new one
        qM = lookupInState key model.state 
        q = case qM of 
                Nothing -> mkq alwaysValid
                Just some_q -> some_q 
    in 
        case q of
            Answered _ _ _ -> Continue model
            Unanswered txt _ err -> Ask (div []
                [ Html.label [] [text label] 
                , input [placeholder label, value txt,  onInput (UpdateQuestion key)] []
                , text err
                , button [onClick (SaveQuestion key txt)] [text "Continue"]
                , button [onClick (GoBack)] [text "Go back"]
                ])
        

