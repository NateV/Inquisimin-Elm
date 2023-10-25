module CustomViewsInterview exposing (..)

import Browser
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Inquisimin exposing (..)
import Dict

{-| An interview that demonstrates how to use a custom Model type, custom views, and non-linear interview paths like collections of values and branching paths. 

This interview also demonstrates how to store History in an interview, so that the interview can go 'back' to previous questions.

-}


type Fruit = Apple
           | Pear
           | Banana


showFruit : Fruit -> String
showFruit f = case f of 
    Apple -> "Apple"
    Pear -> "Pear"
    Banana -> "Banana"

{-| Read a fruit from a string. Maybe.
-}
readFruit : String -> Maybe Fruit
readFruit frt = case frt of 
    "Apple" -> Just Apple
    "Pear" -> Just Pear
    "Banana" -> Just Banana
    _ -> Nothing




{-| The data this interview is supposed to collect 
-}
type alias Results = 
    { firstName : String
    , age : Int
    , fruit : Fruit
    }


type YesNoUnknown = Yes | No | Unknown

type alias PizzaResults = 
    { pizzaType : String }

type alias Model = 
    { interviewState : InterviewState
    , history : List InterviewState
    }

type alias InterviewState = 
    { firstName : Question String
    , age : Question Int
    , fruit : Question Fruit
    , pizza : Question String
    , pizzaChoice : YesNoUnknown
    , colors : Collection String
    }



main : Program () Model Msg
main = Browser.sandbox {init = init, update = update, view = view}



{-| The init function is just a copy of the model with blank unanswered questions. The mkq helper 
gives a shortcut to creating an empty question of the right type. -}
init : Model
init = 
    Model 
        (InterviewState 
            (mkq alwaysValid) 
            (mkq requireInt) 
            (mkq requireFruit)
            (mkq alwaysValid)
            Unknown
            (mkCollection alwaysValid))
        []



requireInt : String -> Valid Int
requireInt txt = case String.toInt txt of
    Just i -> Valid i
    Nothing -> Error (txt ++ " is not an integer.")

requireFruit : String -> Valid Fruit
requireFruit txt = case readFruit txt of 
    Just fruit -> Valid fruit
    Nothing -> Error ("'" ++ txt ++ "' is not the name of an allowed fruit.")


myinterview : Model -> Interview Model (Html Msg)
myinterview m = Interview 
    m 
    ( \m_-> m_ 
      |> ask askfname 
      |> ask askAge
      |> ask askFruit 
      |> ask askPizza
      |> ask collectColors
    )
    showResults







type Msg = UpdateName String
         | UpdateAge String
         | UpdateFruit String
         | SaveName
         | SaveAge
         | SaveFruit
         | ChoosePizza YesNoUnknown
         | UpdatePizza String
         | SavePizza 
         | UpdateColor Int String
         | AddAnotherColor
         | FinishColors
         | GoBack

update : Msg -> Model -> Model
update msg model = 
    let 
        interviewState = model.interviewState
    in 
        case msg of
            UpdateName n -> { model | interviewState = { interviewState | firstName = updateQuestion n interviewState.firstName }}
            UpdateAge a -> { model | interviewState = { interviewState | age = updateQuestion a interviewState.age }}
            UpdateFruit f -> { model | interviewState = { interviewState | fruit = updateQuestion f interviewState.fruit }}
            SaveName -> { model | interviewState = { interviewState | firstName = completeQuestion interviewState.firstName }, history = model.interviewState :: model.history}
            SaveAge -> { model | interviewState = { interviewState | age = completeQuestion interviewState.age }, history = model.interviewState :: model.history}
            SaveFruit -> { model | interviewState = { interviewState | fruit = completeQuestion interviewState.fruit }, history = model.interviewState :: model.history}
            ChoosePizza ynu ->  { model | interviewState = { interviewState | pizzaChoice = ynu }, history = model.interviewState :: model.history}
            UpdatePizza p -> { model | interviewState = { interviewState | pizza = updateQuestion p interviewState.pizza }}
            SavePizza -> { model | interviewState = { interviewState | pizza = completeQuestion interviewState.pizza }, history = model.interviewState :: model.history}
            UpdateColor idx txt -> { model | interviewState = { interviewState | colors = updateItemText interviewState.colors idx txt }}
            AddAnotherColor -> { model | interviewState = { interviewState | colors = addNewColor interviewState.colors }}
            FinishColors -> { model | interviewState = { interviewState | colors = setComplete interviewState.colors Complete}, history = model.interviewState :: model.history}
            GoBack -> goBack model

goBack : Model -> Model
goBack { interviewState, history } = case history of 
    [] -> Model interviewState history
    prev::rest -> Model prev rest

addNewColor : Collection String -> Collection String
addNewColor (Collection complete starter dct) = 
    let 
        newId = getNewId (Collection complete starter dct)
    in
        Collection complete starter (Dict.insert newId starter dct)

{-| Attempt to parse the results of the interview from the collected data.

-}
getResults : Model -> Maybe Results
getResults model = 
    let 
        fnameM = getAnswer model.interviewState.firstName
        ageM = getAnswer model.interviewState.age
        fruitM = getAnswer model.interviewState.fruit
    in
        case (fnameM, ageM, fruitM) of 
            (Just fname, Just age, Just fruit) -> Just (Results fname age fruit)
            _ -> Nothing



-- HTML

view : Model -> Html Msg
view model = 
    div [] [
        div []
            [ h3 [] [text "My important interview"]
            , displayModelSoFar model ],
        div []
            --[ doInterview model]
            [runInterview (myinterview model)]
            , button [onClick GoBack] [text "Go back"]
            ]
            

displayModelSoFar : Model -> Html msg
displayModelSoFar model = 
    div [] 
        [ div []
            [ div [] [(text "Name:"),  (text << getQValue) model.interviewState.firstName]]
        , div []
            [ div [] [text "Age:", (text << getQValue) (model.interviewState.age) ]]
        , div []
            [ div [] [text "Fruit: ",(text << getQValue) model.interviewState.fruit ]]
        , div []
            [ div [] [text "Pizza? ",(text << getQValue) model.interviewState.pizza ]]
       ]

collectColors : Model -> Interviewer Model (Html Msg)
collectColors model = case (getComplete model.interviewState.colors) of
    Complete -> Continue model
    Incomplete -> Ask (collectColors_ model)


collectColors_ : Model ->  (Html Msg)
collectColors_ model = div [] (
    (List.map collectColor (getQuestions model.interviewState.colors) ++ 
        [ button [onClick AddAnotherColor] [text "+"]
        , button [onClick FinishColors] [text "Finish Colors"]
        ])
    ) 

collectColor  : (Int, Question String) -> Html Msg
collectColor (idx, q) = 
    let 
        txt = getQValue q
    in 
        div []
            [ text (String.fromInt idx)
            , input [placeholder "a color", value txt, onInput (UpdateColor idx) ] []
            ]


askfname : Model -> Interviewer Model (Html Msg)
askfname model = case model.interviewState.firstName of 
    Answered _ _ _ -> Continue model
    Unanswered txt _ err  -> Ask (div [] 
        [ text "Name?"
        , input [placeholder "fname", value txt, onInput UpdateName] [] 
        , text err
        , button [onClick SaveName] [text "Continue"]
        ])

askAge : Model -> Interviewer Model (Html Msg)
askAge model = case model.interviewState.age of 
    Answered _ _ _-> Continue model
    Unanswered txt _ err-> Ask (div []
        [ text "Age?"
        , input [placeholder "age", value txt,  onInput UpdateAge] []
        , text err
        , button [onClick SaveAge] [text "Continue"]
            ])

askFruit : Model -> Interviewer Model (Html Msg)
askFruit model = case model.interviewState.fruit of 
    Answered _ _ _-> Continue model
    Unanswered txt _ err -> Ask (div []
        [ text "A fruit?"
        , input [placeholder "fruit", value txt, type_ "text", onInput UpdateFruit] []
        , text err
        , button [onClick SaveFruit] [text "Continue"]
            ])

{-| Find out if a user wants to record details of pizza. If so, send the user to questions about pizza.
-}
askPizza : Model -> Interviewer Model (Html Msg)
askPizza model = case model.interviewState.pizzaChoice of 
    -- ask the pizza question to user.
    Yes -> (askPizzaDetails model)
    -- C
    No -> Continue model 
    -- ask if want to check pizza.
    Unknown -> Ask (div []
        [ text "Do you want some pizza?"
        , button [onClick (ChoosePizza Yes)] [text "Yes"]
        , button [onClick (ChoosePizza No)] [text "No"]
        ])


{-| Ask for details of pizza. 

This could be extended as a chain of questions
-} 
askPizzaDetails : Model -> Interviewer Model (Html Msg)
askPizzaDetails model = case model.interviewState.pizza of 
    Answered _ _ _-> Continue model
    Unanswered txt _ err -> Ask (div [] 
        [ input [placeholder "pizza deets", value txt, onInput UpdatePizza] []
        , text err
        , button [onClick SavePizza] [text "Continue"]
        ])





showResults : Model  -> (Html Msg)
showResults model = (div [] 
        ((h3 [] [text "Here are the results."]) :: (showResult_ model)))


showResult_ : Model -> List (Html Msg)
showResult_ model = case (getQAnswer model.interviewState.firstName, getQAnswer model.interviewState.fruit, getQAnswer model.interviewState.age) of 
    (Just fn, Just fruit, Just age) -> 
        [ p [] [text fn]
        , p [] [text << showFruit <| fruit]
        , p [] [text << String.fromInt <| age]
        ]
    _ -> [p [] [text "Model incomplete."]]


