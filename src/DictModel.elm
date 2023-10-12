module DictModel exposing (..)

{- This module provides methods for making interviews really, really quickly at the cost of 
input validation. This module provides helpers for making interviews that store state in a dictionary. You can only ask one question per step of the interview, and the values are all stored as text. 

This method of making Inquisimin interviews is called the 'DictModel' method because the interivew's state is kept in an `OrderedDict String String`

DictModel interviews rely on some things from [Inquisimin.elm](Inquisimin.elm) so check out the docs there too.

# The DictModel
@docs DictModel

@docs mkDictModel

@docs Msg

# Changing the stored interview state in a `DictModel`.

The question that gets asked to the user depends on the current interview state, so these functions also 
help direct which question is going to get asked to the user.

@docs updateDictModel, previousQuestion, lookupQuestion, checkChoice

# Creating Questionviews to present to the user.
@docs mkDictModelInterviewView, mkTextQuestionView, mkSelectQuestionView 


# Other utils
@docs displayDictModel

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

{-| All DictModel interviews share this DictModel type, which is just a Dict.

-}
type alias DictModel = ODict.OrderedDict String (Question String)


{-| Make the initial model for a DictModel interview with this empty dictionary.

Note that for this to work, every `Question a` in the interview has to have the same `a` type. 
This is why DictModel cannot do any validation or store any values other than `String` values in the interview's state. Every Question has too be a `Question String`.
-}
mkDictModel : ODict.OrderedDict String (Question String)
mkDictModel = ODict.empty


{-| Respond to a message and update the DictModel's interivew state appropriately. 

-}
updateDictModel : Msg -> DictModel -> DictModel
updateDictModel msg model = 
    case msg of
        UpdateQuestion k txt -> ODict.insert k (updateQuestion txt (mkq alwaysValid)) model
        SaveQuestion k txt -> ODict.remove k model
            |> ODict.insert k (Answered txt txt (\t -> Valid t))
        StartOver -> ODict.empty
        GoBack -> case previousQuestion model of 
            Nothing -> model
            Just (pqkey, pq) -> ODict.insert pqkey (unanswer pq) model
    

{-| Find the last question the user answered 

If the interview is already at the beginning, this evaluates to `Nothing`.

-}
previousQuestion : DictModel -> Maybe (String, (Question String))
previousQuestion model = 
    case ODict.toList model of
        [] -> Nothing
        first::_ -> Just first


{-| Try to find a question in the DictModel based on the Question's key.

-}
lookupQuestion : String -> DictModel -> Maybe (Question String)
lookupQuestion key model = ODict.get key model


{-| Display the current value of a DictModel 

-}
displayDictModel : DictModel -> Html Msg
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

{-| Create a simple view for displaying a DictModel interview. 

-}
mkDictModelInterviewView : (DictModel -> Interview DictModel (Html Msg)) -> DictModel -> Html Msg
mkDictModelInterviewView interview model = div [] 
    [ h2 [] [text "Dict DictModel Interview"]
    , displayDictModel model
    , runInterview (interview model)
    ]


{-| Helper to create a simple one-question view that 
asks a single question.

Takes a predictate Question that is Answered or Unanswered.
And Takes a label
-}
mkTextQuestionView : String -> String -> DictModel -> Interviewer DictModel (Html Msg)
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
        

{-|  Create a QuestionView that displays a Select dropdown.

-}
mkSelectQuestionView : String -> String -> List (String, String) -> DictModel -> Interviewer DictModel (Html Msg)
mkSelectQuestionView key label options model = 
    let
        qM = ODict.get key model
        q = case qM of 
            Nothing -> mkq alwaysValid
            Just some_q -> some_q
        mkoption : (String, String) -> Html Msg
        mkoption (val,optlabel) = option [value val] [text optlabel]
        mkoptions : List (String, String) -> List (Html Msg)
        mkoptions opts = List.map mkoption opts
    in
        case q of 
            Answered _ _ _ -> Continue model
            Unanswered selected _ err -> Ask (div []
                [ Html.label [] [text label]
                , select [onInput (UpdateQuestion key)] (mkoptions options)
                , text err
                , button [onClick (SaveQuestion key selected)] [text "Continue"]
                , button [onClick (GoBack)] [text "Go back"]               
                ])

{-| Helps check which branch of a branching path to go down.

  Check if a value has been collected with the key `key`. Then if that value is validly parsed by 
  the reader function (if only we could infer instances of Read, amiright?), return the value wrapped in a Maybe type. Or return Nothing, to indictate the interview still needs to collect the information about which branch to go down. 

-}
checkChoice : (String -> Maybe a) -> String -> DictModel -> Maybe a
checkChoice reader key model = 
    lookupQuestion key model
    |> Maybe.andThen getQAnswer
    |> Maybe.andThen reader


