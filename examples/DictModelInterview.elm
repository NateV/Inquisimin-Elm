module DictModelInterview exposing (..)

import DictModel exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Inquisimin exposing (..)

{-| An Interview demonstrating the DictModel pattern and using DictModel related helpers for making user views. This is the simplest way to make an interview with Inquisimin, and also the most constrained. -}

main : Program () Model Msg
main = Browser.sandbox 
    { init = mkDictModel 
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


