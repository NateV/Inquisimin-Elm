module V2 exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Inquisimin exposing (..)





type Fruit = Apple
           | Pear
           | Banana



type alias Model = 
    { firstName : Question String
    , age : Question Int
    , fruit : Question Fruit
    }



main : Program () Model Msg
main = Browser.sandbox {init = init, update = update, view = view}




{-| The data this interview is supposed to collect 
-}
type alias Results = 
    { firstName : String
    , age : Int
    , fruit : Fruit
    }

{-| The init function is just a copy of the model with blank unanswered questions. The mkq helper 
gives a shortcut to creating an empty question of the right type. -}
init : Model
init = Model (mkq alwaysValid) (mkq requireInt) (mkq requireFruit)


requireInt : String -> Valid Int
requireInt txt = case String.toInt txt of
    Just i -> Valid i
    Nothing -> Error (txt ++ " is not an integer.")

requireFruit : String -> Valid Fruit
requireFruit txt = case readFruit txt of 
    Just fruit -> Valid fruit
    Nothing -> Error ("'" ++ txt ++ "' is not the name of an allowed fruit.")

{-| Read a fruit from a string. Maybe.
-}
readFruit : String -> Maybe Fruit
readFruit frt = case frt of 
    "Apple" -> Just Apple
    "Pear" -> Just Pear
    "Banana" -> Just Banana
    _ -> Nothing

myinterview : Model -> Interview Model Msg
myinterview m = Interview 
    m 
    ( \m_-> m_ 
      |> ask askfname 
      |> ask askAge
      |> ask askFruit 
    )
    showResults


type Msg = UpdateName String
         | UpdateAge String
         | UpdateFruit String
         | SaveName
         | SaveAge
         | SaveFruit

update : Msg -> Model -> Model
update msg model = 
    case msg of
        UpdateName n -> { model | firstName = updateQuestion n model.firstName }
        UpdateAge a -> { model | age = updateQuestion a model.age }
        UpdateFruit f -> { model | fruit = updateQuestion f model.fruit }
        SaveName -> { model | firstName = completeQuestion model.firstName }
        SaveAge -> { model | age = completeQuestion model.age }
        SaveFruit -> { model | fruit = completeQuestion model.fruit }


{-| Attempt to parse the results of the interview from the collected data.

-}
getResults : Model -> Maybe Results
getResults model = 
    let 
        fnameM = getAnswer model.firstName
        ageM = getAnswer model.age
        fruitM = getAnswer model.fruit
    in
        case (fnameM, ageM, fruitM) of 
            (Just fname, Just age, Just fruit) -> Just (Results fname age fruit)
            _ -> Nothing



-- HTML

view : Model -> Html Msg
view model =
    div [] [
        div []
            [ displayModelSoFar model ],
        div []
            --[ doInterview model]
            [runInterview (myinterview model)]
            ]


displayModelSoFar : Model -> Html msg
displayModelSoFar model = 
    div [] 
        [ div []
            [ div [] [(text "Name:"),  (text << getQValue) model.firstName]]
        , div []
            [ div [] [text "Age:", (text << getQValue) (model.age) ]]
        , div []
            [ div [] [text "Fruit: ",(text << getQValue) model.fruit ]]
        ]


askfname : Model -> Interviewer Model (Html Msg)
askfname model = case model.firstName of 
    Answered _ _ -> Continue model
    Unanswered txt f err  -> Ask (div [] 
        [ input [placeholder "fname", value txt, onInput UpdateName] [] 
        , text err
        , button [onClick SaveName] [text "Continue"]
        ])

askAge : { a | age : Question b } -> Interviewer { a | age : Question b } (Html Msg)
askAge model = case model.age of 
    Answered _ _ -> Continue model
    Unanswered txt f err-> Ask (div []
        [ input [placeholder "age", value txt,  onInput UpdateAge] []
        , text err
        , button [onClick SaveAge] [text "Continue"]
            ])

askFruit : { a | fruit : Question b } -> Interviewer { a | fruit : Question b } (Html Msg)
askFruit model = case model.fruit of 
    Answered _ _ -> Continue model
    Unanswered txt f err -> Ask (div []
        [ input [placeholder "fruit", value txt, type_ "text", onInput UpdateFruit] []
        , text err
        , button [onClick SaveFruit] [text "Continue"]
            ])

showResults : Interviewer Model (Html Msg)  -> (Html Msg)
showResults modelOrView = case modelOrView of
    Continue model -> (div [] [text "Done."])
    Ask something -> something


