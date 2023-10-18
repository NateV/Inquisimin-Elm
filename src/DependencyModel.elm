module DependencyModel exposing (..)

{-| A style of interview in which we define the interview's ultimate requirements, and use a library of functions to 
satisfy those requirements. Those final requirements might themselves have their own requirements that have to be satisfied.

-}

import Dict exposing (Dict)
import Inquisimin exposing (..)
import Html exposing (Html, div, text)

{-| keys for questionviews and for Questions in state.
-}
type alias Key = String

{-| The model for a dependency-oriented interview. -}
type alias DepModel = 
    { state : Dict Key (Question String) 
    , history : List Key
    , requirements : List Key
    }

mkDepModel : List Key -> DepModel
mkDepModel requirements =
    { state = Dict.empty
    , history = []
    , requirements = requirements
    }

{-| All DictModel interviews share this Msg type.

-}
type Msg = UpdateQuestion String String
         | SaveQuestion String String
         | StartOver
         | GoBack 

{-| The library of questions 
-}
type Library = Library (Dict Key (QuestionView DepModel (Html Msg)) )

type Requirements 
    = Satisfied 
    | Unsatisfied DepModel (List Key)

require : List Key -> DepModel -> Requirements
require keys model = 
    let 
        stateKeys = Dict.keys model.state
        missingKeys = getMissing stateKeys keys 
    in 
        case missingKeys of 
            [] -> Satisfied 
            missing -> Unsatisfied model missing

andThen : Html Msg -> Requirements -> Interviewer DepModel (Html Msg)
andThen q req = case req of 
    Unsatisfied model needed -> Continue (pushToState model needed)
    Satisfied -> Ask q




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






