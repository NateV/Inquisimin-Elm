module DependencyModel exposing (..)

{-| A style of interview in which we define the interview's ultimate requirements, and use a library of functions to 
satisfy those requirements. Those final requirements might themselves have their own requirements that have to be satisfied.

-}

import Dict exposing (Dict)
import Inquisimin exposing (..)
import Html exposing (Html, div, input, button, text)
import Html.Attributes exposing (placeholder, value)
import Html.Events exposing (onClick, onInput)



{-| All DictModel interviews share this Msg type.

-}
type Msg = UpdateQuestion String String
         | SaveQuestion String String
         | StartOver
         | GoBack 


updateDepModel : Msg -> DepModel -> DepModel
updateDepModel msg model = 
    case msg of
        UpdateQuestion k txt -> update k txt model
        SaveQuestion k txt -> save k txt model
        StartOver -> empty model
        GoBack -> case previousQuestion model of 
            Nothing -> model
            Just (pqkey, pq) -> goback pqkey pq model


goback : Key -> Question String -> DepModel -> DepModel
goback arg1 arg2 arg3 =
    Debug.todo "TODO"

{-| Update a question in the DepModel.
-}
update : Key -> String -> DepModel -> DepModel
update key txt model = { model | state = updateModelState key txt model.state }

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
mkDepModelView : Library -> (DepModel -> Html Msg) -> DepModel -> Html Msg
mkDepModelView lib endView model = div []
    [ div [] [text "The interview"]
    , findQToAsk lib endView model
    ]

findQToAsk : Library -> (DepModel -> Html Msg) -> DepModel ->  (Html Msg) 
findQToAsk lib endView model = Debug.todo "no idea"


        

{-| The library of questions 

-}
type Library = Library (Dict Key (QuestionView DepModel (Html Msg)) )


{-| Try to find a question in the Library -}
lookupInLibrary : Key -> Library -> Maybe (QuestionView DepModel (Html Msg))
lookupInLibrary key (Library lib) = Dict.get key lib  

type Requirements 
    = Satisfied  DepModel
    | Unsatisfied DepModel (List Key)

require : List Key -> DepModel -> Requirements
require keys model = 
    let 
        stateKeys = Dict.keys model.state
        missingKeys = getMissing stateKeys keys 
    in 
        case missingKeys of 
            [] -> Satisfied model 
            missing -> Unsatisfied model missing

deprecatedandThen : Html Msg -> Requirements -> Interviewer DepModel (Html Msg)
deprecatedandThen q req = case req of 
    Unsatisfied model needed -> Continue (pushToState model needed)
    Satisfied model -> Ask q




pushToState : DepModel -> List Key -> DepModel
pushToState model neededKeys = {model | requirements = neededKeys ++ model.requirements}

{-| Find any items in `required` that are not in `acquired`

    getMissing ["a","b"] ["b"] == ["a"]
-}
getMissing : List Key -> List Key -> List Key
getMissing acquired required = List.foldl (checkMissing acquired) [] required


checkMissing : List Key -> Key -> List Key -> List Key
checkMissing acquired key acc = 
    if List.member key acquired 
        then acc 
        else key :: acc 






{-| Helper to create a simple one-question view that 
asks a single question.

Takes a predictate Question that is Answered or Unanswered.
And Takes a label
-}
mkTextQuestionView : String -> String -> DepModel -> Interviewer DepModel (Html Msg)
mkTextQuestionView key label model = 
    let 
        -- find q in the model or make a new one
        qM = Dict.get key model.state
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
        

