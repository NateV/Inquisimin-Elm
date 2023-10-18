module DependencyModelExample exposing (..)

import Browser
import Inquisimin exposing (..)
import DependencyModel exposing (..)
import DictModel exposing (mkTextQuestionView)
import Dict
import Html exposing (Html)


main : Program () DepModel Msg
main = Browser.sandbox
    { init = mkDepModel ["name"]
    , update = updateDepModel
    , view = mkDepModelView myLib
    }

myLib : Library
myLib = Library <|
    Dict.fromList 
        [ ("name", nameQ)
        , ("age", ageQ)
        ]



nameQ : QuestionView DepModel (Html Msg)
nameQ model = model
    |> require ["age"] 
    |> andThen (mkTextQuestionView "name" "Whats your Name")

ageQ : QuestionView DepModel (Html Msg)
ageQ model = mkTextQuestionView "age" "Whats your age"




