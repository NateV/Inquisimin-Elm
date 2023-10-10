module DictModel exposing (..)

{- This module provides methods for making interviews really, really quickly at the cost of 
    input validation. This module provides helpers for making interviews that store state in a dictionary. You can only ask one question per step of the interview, and the values are all stored as text. 
-} 

import Html exposing (..)
import Inquisimin exposing (..)
import OrderedDict as ODict
import Html.Events exposing (onInput, onClick)
import Html.Attributes exposing (..)

{-| All DictModel interviews share this Msg type.

-}
type Msg = UpdateQuestion String String
         | SaveQuestion String String
         | StartOver
         | GoBack 

{-| All DictModel interviews share this Model type, which is just a Dict.-}
type alias Model = ODict.OrderedDict String (Question String)


{-| Make the initial model for a DictModel interview with this empty dictionary.

    Note that for this to work, every `Question a` in the interview has to have the same `a` type. 
    This is why DictModel cannot do any validation or store any values other than `String` values in the interview's state. Every Question has too be a `Question String`.
-}
mkDictModel : ODict.OrderedDict String (Question String)
mkDictModel = ODict.empty


updateDictModel : Msg -> Model -> Model
updateDictModel msg model = 
    case msg of
        UpdateQuestion k txt -> ODict.insert k (updateQuestion txt (mkq alwaysValid)) model
        SaveQuestion k txt -> ODict.remove k model
            |> ODict.insert k (Answered txt txt (\t -> Valid t))
        StartOver -> ODict.empty
        GoBack -> case previousQuestion model of 
            Nothing -> model
            Just (pqkey, pq) -> ODict.insert pqkey (unanswer pq) model
    
previousQuestion : Model -> Maybe (String, (Question String))
previousQuestion model = 
    case ODict.toList model of
        [] -> Nothing
        first::_ -> Just first

lookupQuestion : String -> Model -> Maybe (Question String)
lookupQuestion key model = ODict.get key model


{-| Display the current value of a DictModel 

-}
displayDictModel : Model -> Html Msg
displayDictModel model = div []
    [ div [] <| 
        ODict.foldl (diplayModelPiece) [h3 [] [text "Model:"]] model 
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
        qM = ODict.get key model
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
    


{-| Helps check which branch of a branching path to go down.

  Check if a value has been collected with the key `key`. Then if that value is validly parsed by 
  the reader function (if only we could infer instances of Read, amiright?), return the value wrapped in a Maybe type. Or return Nothing, to indictate the interview still needs to collect the information about which branch to go down. 

-}
checkChoice : (String -> Maybe a) -> String -> Model -> Maybe a
checkChoice reader key model = 
    lookupQuestion key model
    |> Maybe.andThen getQAnswer
    |> Maybe.andThen reader


