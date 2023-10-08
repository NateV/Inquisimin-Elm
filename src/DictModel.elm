module DictModel exposing (..)

{- This module provides methods for making interviews really, really quickly at the cost of 
    input validation. This module provides helpers for making interviews that store state in a dictionary. You can only ask one question per step of the interview, and the values are all stored as text. 
-} 

import Html exposing (..)
import Inquisimin exposing (..)
import Dict
import Html.Events exposing (onInput, onClick)
import Html.Attributes exposing (..)

{-| All DictModel interviews share this Msg type.

-}
type Msg = UpdateQuestion String String
         | SaveQuestion String String
         | StartOver

{-| All DictModel interviews share this Model type, which is just a Dict.-}
type alias Model = Dict.Dict String (Question String)


{-| Make the initial model for a DictModel interview with this empty dictionary.

    Note that for this to work, every `Question a` in the interview has to have the same `a` type. 
    This is why DictModel cannot do any validation or store any values other than `String` values in the interview's state. Every Question has too be a `Question String`.
-}
mkDictModel : Dict.Dict String (Question String)
mkDictModel = Dict.empty


updateDictModel : Msg -> Model -> Model
updateDictModel msg model = 
    case msg of
        UpdateQuestion k txt -> Dict.insert k (updateQuestion txt (mkq alwaysValid)) model
        SaveQuestion k txt -> Dict.remove k model
            |> Dict.insert k (Answered txt txt (\t -> Valid t))
        StartOver -> Dict.empty


{-| Display the current value of a DictModel 

-}
displayDictModel : Model -> Html Msg
displayDictModel model = div []
    [ div [] <| 
        Dict.foldl (diplayModelPiece) [h3 [] [text "Model:"]] model 
        ++ 
        [div [] 
            [ button [onClick StartOver] [text "Start Over"]]
        ]
    ]


diplayModelPiece : String -> Question String -> List (Html Msg) -> List (Html Msg)
diplayModelPiece key question acc = acc ++ [ 
    div [] 
        [ text key
        , text ": "
        , text << getQValue <| question
        ]]

mkDictModelInterviewView : (Model -> Interview Model (Html Msg)) -> Model -> Html Msg
mkDictModelInterviewView interview model = div [] 
    [ h2 [] [text "Dict Model Interview"]
    , displayDictModel model
    , runInterview (interview model)
    ]


{-| Helper to create a simple one-question view that 
asks a single question.

Takes a predictate Question that is Answered or Unanswered.
And Takes a label
-}
mkTextQuestionView : String -> String -> Model -> Interviewer Model (Html Msg)
mkTextQuestionView key label model = 
    let 
        -- find q in the model or make a new one
        qM = Dict.get key model
        q = case qM of 
            Nothing -> mkq alwaysValid
            Just some_q -> some_q 
    in 
        

    case q of
    Answered _ _ _ -> Continue model
    Unanswered txt _ err -> Ask (div []
        [ input [placeholder label, value txt,  onInput (UpdateQuestion key)] []
        , text err
        , button [onClick (SaveQuestion key txt)] [text "Continue"]
            ])



