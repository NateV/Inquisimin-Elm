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
        |> ask pizzaOrDessert
        |> ask cattype)
    displayDictModel 

{-| The root of a branch, which decides which path to go down. 
-}
pizzaOrDessert : Model -> Interviewer Model (Html Msg)
pizzaOrDessert model = case checkChoice readPizzaOrDessert "pizza" model of
    Just Pizza -> pizzaBranch model
    Just Dessert -> dessertBranch model
    Nothing -> mkTextQuestionView "pizza" "Pizza or Dessert?" model

dessertBranch : Model -> Interviewer (Model) (Html Msg)
dessertBranch model = 
    Continue model 
    |> ask (mkTextQuestionView "dessert" "Favorite type of dessert?")
    |> ask (mkTextQuestionView "topping" "Favorite desert topping?")

pizzaBranch : Model -> Interviewer (Model) (Html Msg)
pizzaBranch model =
    Continue model
    |> ask (mkTextQuestionView "topping" "Favorite pizza topping?")
    |> ask (mkTextQuestionView "size" "What size?") 

askfname : Model -> Interviewer (Model) (Html Msg) 
askfname model = mkTextQuestionView "firstname"  "First Name" model

-- a dictmodel question in point-free style.
cattype : Model -> Interviewer (Model) (Html Msg)
cattype = mkTextQuestionView "cattype" "Cat Type"


