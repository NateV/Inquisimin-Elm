module DictModelInterview exposing (..)

import DictModel exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Inquisimin exposing (..)
import Dict



main : Program () Model Msg
main = Browser.sandbox 
    { init = Dict.empty
    , update = updateDictModel
    , view = mkDictModelInterviewView interview
    }



interview : Model -> Interview Model (Html Msg)
interview m = Interview m
    (\m_ -> m_
        |> ask askfname
        |> ask cattype)
    displayDictModel 

askfname : Model -> Interviewer (Model) (Html Msg) 
askfname model = mkTextQuestionView "firstname"  "First Name" model

-- a dictmodel question in point-free style.
cattype : Model -> Interviewer (Model) (Html Msg)
cattype = mkTextQuestionView "cattype" "Cat Type"


