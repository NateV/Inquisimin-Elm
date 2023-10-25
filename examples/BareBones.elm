module BareBones exposing (..)

{-| Bare bones example of the a raw approach to guided interviews -}

import Browser
import Html exposing (..)
import Html.Events as E

type Spooky = VerySpooky
            | NotSoSpooky

type Candy = FullBars
           | FunSize

type Present = Home
             | NotHome
                

type alias Model = 
    { spookiness : Maybe Spooky
    , candy : Maybe Candy
    , present : Maybe Present
    }

init :Model
init = Model Nothing Nothing Nothing

type Msg = SetSpooky Spooky
         | SetCandy Candy
         | SetPresent Present

update : Msg -> Model -> Model
update msg model = case msg of
    SetSpooky s -> { model | spookiness = Just s }
    SetCandy c -> { model | candy = Just c }
    SetPresent p -> { model | present = Just p }




main = Browser.sandbox {init = init, update = update, view = view}

view : Model -> Html Msg
view model = div []
    [ showResults model
    , pickQ model
    ]

pickQ : Model -> Html Msg
pickQ model = 
    case (model.spookiness, model.candy, model.present) of
        (Nothing, Nothing, Nothing) -> askSpooky
        (Just _, Nothing, Nothing) -> askCandy
        (Just _, Just _, Nothing) -> askPresent
        _ -> showResults model


askSpooky : Html Msg
askSpooky =
    div [] 
        [ h3 [] [text "Spooky?"]
        , button [E.onClick <| SetSpooky VerySpooky] [text "Spooky"]
        , button [E.onClick <| SetSpooky NotSoSpooky] [text "Not"]
        ]


askCandy : Html Msg
askCandy =
    div [] 
        [ h3 [] [text "candy?"]
        , button [E.onClick <| SetCandy FullBars] [text "Full bars"]
        , button [E.onClick <| SetCandy FunSize] [text "Fun size"]
        ]


askPresent : Html Msg
askPresent =
    div [] 
        [ h3 [] [text "Present?"]
        , button [E.onClick <| SetPresent Home] [text "Home"]
        , button [E.onClick <| SetPresent NotHome] [text "Not home"]
        ]




showResults : Model -> Html Msg
showResults model =
    div []
        [ h3 [] [text "Results"]
        , h5 [] [text <| showSpooky model.spookiness] 
        , h5 [] [text <| showCandy model.candy] 
        , h5 [] [text <| showPresent model.present] 
        ]


showSpooky : Maybe Spooky -> String
showSpooky s = case s of 
    Nothing -> "--"
    Just VerySpooky -> "Spooky"
    Just NotSoSpooky -> "Not So Spooky"


showCandy : Maybe Candy -> String
showCandy c = case c of
    Nothing -> "--"
    Just FullBars -> "Fullbars"
    Just FunSize -> "FunSize"



showPresent : Maybe Present -> String
showPresent p = case p of
    Nothing -> "--"
    Just Home -> "Home"
    Just NotHome -> "Not home"
