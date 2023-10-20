module DependencyModelExample exposing (..)

import Browser
import Inquisimin exposing (..)
import DependencyModel exposing (..)
import Dict
import Html exposing (input, button, Html, div, text)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onClick)


main : Program () DepModel Msg
main = Browser.sandbox
    { init = mkDepModel ["name"]
    , update = updateDepModel
    , view = mkDepModelView myLib theend
    }

theend : DepModel -> Html Msg
theend model = div [] [text "all done"] 

myLib : Library
myLib = Library <|
    Dict.fromList 
        [ ("name", nameQ)
        , ("age", ageQ)
        ]



{-|  A questionView in a DepModel interview 

-}
nameQ : QuestionView DepModel (Html Msg)
nameQ model = 
        model
        |> require ["age"] 
        |> andThen (mkTextQuestionView "name" "What's your name") 


andThen : QuestionView DepModel (Html Msg) -> Requirements -> Interviewer DepModel (Html Msg)
andThen q req = case req of 
    Unsatisfied model needed -> Continue (pushToState model needed)
    Satisfied model -> q model


ageQ : QuestionView DepModel (Html Msg)
ageQ = mkTextQuestionView "age" "Whats your age"




