module DictModelInterview exposing (..)

import DictModel exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Inquisimin exposing (..)

{-| An Interview demonstrating the DictModel pattern and using DictModel related helpers for making user views. This is the simplest way to make an interview with Inquisimin, and also the most constrained. -}

main : Program () DictModel Msg
main = Browser.sandbox 
    { init = mkDictModel 
    , update = updateDictModel
    , view = mkDictModelInterviewView interview
    }



interview : DictModel -> Interview DictModel (Html Msg)
interview m = Interview m
    (\m_ -> m_
        |> ask askfname
        |> ask cattype
        |> ask askdessert)
    displayDictModel 


askfname : DictModel -> Interviewer DictModel (Html Msg) 
askfname model = mkTextQuestionView "firstname"  "First Name" model

-- a dictmodel question in point-free style.
cattype : DictModel -> Interviewer DictModel (Html Msg)
cattype = mkTextQuestionView "cattype" "Cat Type"

askdessert : QuestionView DictModel (Html Msg)
askdessert = mkSelectQuestionView "dessert" "Dessert?" [("pie","Pie"),("icecream","IceCream")]
