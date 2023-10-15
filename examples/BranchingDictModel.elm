module BranchingDictModel exposing (..)

import DictModel exposing (..)
import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Inquisimin exposing (..)

{-| An interview demonstarting that DictModel interviews can do branching.



-}


type PizzaOrDessert = Pizza | Dessert

readPizzaOrDessert : String -> Maybe PizzaOrDessert
readPizzaOrDessert pd = case pd of 
    "Pizza" -> Just Pizza
    "Dessert" -> Just Dessert 
    _ -> Nothing

-- Main program

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
        |> ask lname
        |> ask pizzaOrDessert
        |> ask cattype)
    displayDictModel 

lname : QuestionView DictModel (Html Msg)
lname = mkTextQuestionView "lname" "Last name"


{-| The root of a branch, which decides which path to go down. 
-}
pizzaOrDessert : DictModel -> Interviewer DictModel (Html Msg)
pizzaOrDessert model = case checkChoice readPizzaOrDessert "pizzaordessert" model of
    Just Pizza -> pizzaBranch model
    Just Dessert -> dessertBranch model
    Nothing -> mkSelectQuestionView "pizzaordessert" "Pizza or Dessert?" [("Pizza","Pizza"),("Dessert","Dessert")] model

dessertBranch : DictModel -> Interviewer (DictModel) (Html Msg)
dessertBranch model = 
    Continue model 
    |> ask (mkTextQuestionView "dessert" "Favorite type of dessert?")
    |> ask (mkTextQuestionView "topping" "Favorite desert topping?")

pizzaBranch : DictModel -> Interviewer (DictModel) (Html Msg)
pizzaBranch model =
    Continue model
    |> ask (mkTextQuestionView "topping" "Favorite pizza topping?")
    |> ask (mkTextQuestionView "size" "What size?") 

askfname : DictModel -> Interviewer (DictModel) (Html Msg) 
askfname model = mkTextQuestionView "firstname"  "First Name" model

-- a dictmodel question in point-free style.
cattype : DictModel -> Interviewer (DictModel) (Html Msg)
cattype = mkTextQuestionView "cattype" "Cat Type"


