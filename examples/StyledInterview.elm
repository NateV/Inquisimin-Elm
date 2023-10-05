module StyledInterview exposing (..)

import Browser
import Html exposing (Html)
--import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Inquisimin exposing (..)
import Dict
import Element exposing (Element, none, width, el, fill, row, text, spacing, column)
import Element.Input as I
import Element.Font as F



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
        (mkq alwaysValid) 
        (mkq requireInt) 
        (mkq requireFruit)
        (mkq alwaysValid)
        Unknown
        (mkCollection alwaysValid)



requireInt : String -> Valid Int
requireInt txt = case String.toInt txt of
    Just i -> Valid i
    Nothing -> Error (txt ++ " is not an integer.")

requireFruit : String -> Valid Fruit
requireFruit txt = case readFruit txt of 
    Just fruit -> Valid fruit
    Nothing -> Error ("'" ++ txt ++ "' is not the name of an allowed fruit.")


myinterview : Model -> Interview Model (Element Msg) 
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

update : Msg -> Model -> Model
update msg model = 
    case msg of
        UpdateName n -> { model | firstName = updateQuestion n model.firstName }
        UpdateAge a -> { model | age = updateQuestion a model.age }
        UpdateFruit f -> { model | fruit = updateQuestion f model.fruit }
        SaveName -> { model | firstName = completeQuestion model.firstName }
        SaveAge -> { model | age = completeQuestion model.age }
        SaveFruit -> { model | fruit = completeQuestion model.fruit }
        ChoosePizza ynu ->  { model | pizzaChoice = ynu }
        UpdatePizza p -> { model | pizza = updateQuestion p model.pizza }
        SavePizza -> { model | pizza = completeQuestion model.pizza }
        UpdateColor idx txt -> { model | colors = updateItemText model.colors idx txt }
        AddAnotherColor -> { model | colors = addNewColor model.colors }
        FinishColors -> { model | colors = setComplete model.colors Complete}

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
        fnameM = getAnswer model.firstName
        ageM = getAnswer model.age
        fruitM = getAnswer model.fruit
    in
        case (fnameM, ageM, fruitM) of 
            (Just fname, Just age, Just fruit) -> Just (Results fname age fruit)
            _ -> Nothing



-- HTML

view : Model -> Html Msg
view model = Element.layout [width fill, Element.explain Debug.todo] <|
    column [spacing 10, width fill] 
        [ displayModelSoFar model
        , row [width fill] 
            [ el [width fill] none
            , el [width fill] <| runInterview (myinterview model)
            , el [width fill] none
            ]
        ]
            

displayModelSoFar : Model -> Element Msg
displayModelSoFar model = 
    column [width fill] 
            [ row [width fill] [(text "Name:"),  (text << getQValue) model.firstName]
            , row [width fill] [text "Age:", (text << getQValue) (model.age) ]
            , row [width fill] [text "Fruit: ",(text << getQValue) model.fruit ]
            , row [width fill] [text "Pizza? ",(text << getQValue) model.pizza ]
            ]

collectColors : Model -> Interviewer Model (Element Msg)
collectColors model = case (getComplete model.colors) of
    Complete -> Continue model
    Incomplete -> Ask (collectColors_ model)


collectColors_ : Model ->  (Element Msg)
collectColors_ model = row [] (
    (List.map collectColor (getQuestions model.colors) ++ 
        [ I.button [] {onPress = Just AddAnotherColor, label= text "+"}
        , I.button [] {onPress = Just FinishColors, label = text "Finish Colors"}
        ])
    ) 

collectColor  : (Int, Question String) -> Element Msg
collectColor (idx, q) = 
    let 
        txt = getQValue q
    in 
        row []
            [ text (String.fromInt idx)
            , I.text [] {label = I.labelLeft [] (text "Color?"), text= txt, placeholder= Just <| I.placeholder [] (text "a color"), onChange= (UpdateColor idx) }
            ]


askfname : Model -> Interviewer Model (Element Msg)
askfname model = case model.firstName of 
    Answered _ _ _ -> Continue model
    Unanswered txt _ err  -> Ask (column [width fill] 
        [ I.text [width fill] {label = I.labelLeft [] (text "First Name"), placeholder= Just <| I.placeholder [] (text "fname"), text=txt, onChange= UpdateName} 
        , text err
        , I.button [] {onPress =Just SaveName, label= text "Continue"}
        ])

askAge : { a | age : Question b } -> Interviewer { a | age : Question b } (Element Msg)
askAge model = case model.age of 
    Answered _ _ _-> Continue model
    Unanswered txt _ err-> Ask (column []
        [ I.text [] {label = I.labelLeft [] (text "Age?"), placeholder =Just <| I.placeholder [] (text "age"), text= txt,  onChange= UpdateAge}
        , text err
        , I.button [] {onPress=Just SaveAge, label= text "Continue"}
            ])

askFruit : { a | fruit : Question b } -> Interviewer { a | fruit : Question b } (Element Msg)
askFruit model = case model.fruit of 
    Answered _ _ _-> Continue model
    Unanswered txt _ err -> Ask (column []
        [ I.text [width fill] {label=I.labelLeft [] (text "Fruit"), placeholder= Just <| I.placeholder [] (text "fruit"), text=txt, onChange= UpdateFruit}
        , text err
        , I.button [] {onPress=Just SaveFruit, label = text "Continue"} 
        ])

{-| Find out if a user wants to record details of pizza. If so, send the user to questions about pizza.
-}
askPizza : Model -> Interviewer Model (Element Msg)
askPizza model = case model.pizzaChoice of 
    -- ask the pizza question to user.
    Yes -> (askPizzaDetails model)
    -- C
    No -> Continue model 
    -- ask if want to check pizza.
    Unknown -> Ask (column []
        [ text "Do you want some pizza?"
        , I.button [] {onPress=Just <| ChoosePizza Yes, label = (text "Yes")}
        , I.button [] {onPress=Just <| ChoosePizza No, label=(text "No")}
        ])


{-| Ask for details of pizza. 

This could be extended as a chain of questions
-} 
askPizzaDetails : Model -> Interviewer Model (Element Msg)
askPizzaDetails model = case model.pizza of 
    Answered _ _ _-> Continue model
    Unanswered txt _ err -> Ask (column [] 
        [ I.text [] {label=I.labelLeft [] (text "Pizza details"), placeholder =Just <| I.placeholder [] (text "pizza deets"), text= txt, onChange= UpdatePizza}
        , text err
        , I.button [] {onPress=Just SavePizza, label = (text "Continue")}        
        ])





showResults : Model  -> (Element Msg)
showResults model = (row [] 
        ((row [F.variant F.smallCaps] [text "Here are the results."]) :: (showResult_ model)))


showResult_ : Model -> List (Element Msg)
showResult_ model = case (getQAnswer model.firstName, getQAnswer model.fruit, getQAnswer model.age) of 
    (Just fn, Just fruit, Just age) -> 
        [ row [] [text fn]
        , row [] [text << showFruit <| fruit]
        , row [] [text << String.fromInt <| age]
        ]
    _ -> [row [] [text "Model incomplete."]]


