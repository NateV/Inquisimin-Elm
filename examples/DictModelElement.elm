module DictModelElement exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Inquisimin exposing (..)
import DictModel exposing (..)

{-| Interview demonstrating how to use Browser.element with a DictModel interview. 
-}


main : Program () DictModel Msg
main = Browser.element
    { init = \_ -> (mkDictModel, Cmd.none) 
    , view = mkDictModelInterviewView interview
    , update = modifiedUpdateDictModel
    , subscriptions = \_ -> Sub.none
    }

{-| 
Wrap DictModel's default `updateDictModel` function in another function that will 

1) pass along the message and model to `updateDictModel`, and 
2) do whatever you want with the commands.

-}
modifiedUpdateDictModel : Msg -> DictModel -> (DictModel, Cmd Msg)
modifiedUpdateDictModel msg model = (updateDictModel msg model, Cmd.none)

interview : DictModel -> Interview DictModel (Html Msg)
interview m = Interview m
    (\m_ -> m_
        |> ask askfname
        |> ask cattype)
    displayDictModel 


askfname : DictModel -> Interviewer DictModel (Html Msg) 
askfname model = mkTextQuestionView "firstname"  "First Name" model

-- a dictmodel question in point-free style.
cattype : DictModel -> Interviewer DictModel (Html Msg)
cattype = mkTextQuestionView "cattype" "Cat Type"


