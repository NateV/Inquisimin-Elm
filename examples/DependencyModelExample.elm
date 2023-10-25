module DependencyModelExample exposing (..)

import Browser
import Inquisimin exposing (..)
import DependencyModel exposing (..)
import Dict
import Html exposing (input, button, Html, div, text)
import Html.Attributes exposing (placeholder)
import Html.Events exposing (onClick)



{-| 

I think I can do conditional logic of something like 
a 'required' key, where the requirement is 'satisfied' 
based on some function, like 'age' in the state being over 65.
-}



main : Program () DepModel DepMsg
main = Browser.sandbox
    { init = mkDepModel ["name"]
    , update = updateDepModel
    , view = mkDepModelView myLib theend
    }

theend : DepModel -> Html DepMsg
theend model = div [] 
    [text "all done"] 

myLib : Library
myLib = Library <|
    Dict.fromList 
        [ ("name", nameQ)
        , ("age", ageQ)
        , ("favfood", favFoodQ)
        ]


favFoodQ : QuestionView DepModel (Html DepMsg)
favFoodQ = mkTextQuestionView "favfood" "What's your favorite food?"

{-|  A questionView in a DepModel interview 

-}
nameQ : QuestionView DepModel (Html DepMsg)
nameQ model = 
        model
        |> require ["age","favfood"] 
        |> thenAsk (mkTextQuestionView "name" "What's your name") 


ageQ : QuestionView DepModel (Html DepMsg)
ageQ = mkTextQuestionView "age" "Whats your age"




