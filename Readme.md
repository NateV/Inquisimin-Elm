# Inquisimin Elm


Simple guided interviews with Elm. 


1. The Goal

Write a type to describe the goal of the interview. 

```elm
type alias Results = 
    { firstName : String
    , age : Int
    , fruit : Fruit
    }
```

2. Model. 

Next we'll add a Model type. This model type will include membesrs of type `Question a`. A `Question a` is a type that:

* stores text from html inputs, while the user is writing it. 
* tracks whether the question is compeleted or not 
* stores a parser that can map the stored String to whatever the Question's goal type is. These parsers should return a value of the type `Valid a` for a `Question a`, or an `Error String` if the `Question`'s parser could not parse the result. 
* stores an error message if the current stored text can't be parsed to `a`.

Here's an example parser:

```
requireInt : String -> Valid Int
requireInt txt = case String.toInt txt of
    Just i -> Valid i
    Nothing -> Error (txt ++ " is not an integer.")


```

`mkq` can help you make a `Question`. 

```
myIntQuestion = mkq requireInt
```

Each single value in the `Results` type will need a `Question`.




3. The Interview

The interview is a chain of `Model -> Either Model (Html Msg)` functions. Combine them with 
`ask `, as in 

```elm
Left model 
|> ask questionView1
|> ask questionView2
```

Add an `Html Msg` at the end which will always display at the end of the interview.

3.  Branching questions

We can handle branching questions. with the following technique. 

If the branch will depend on a user's explicit choice, add a property to the Model that tracks which branch a user is going down. For example 

```
type WantsCakeOrPizza = Yes | No | Unknown 
```

This type needs a value like `Unknown` to mark that at the start of the interview, its not known which branch to go down. 

Create a question (`Model -> Interviewer Model (Html Msg)` for the 'split' of a branch. This question uses a case statement to check which branch to go down. 

An option that doesn't ask any more questions simply evaluates to `Continue model`.
If the the user needs to provide some input, the question should evaluate to `Ask (Html Msg)`. 
This might be a question asking the user about which branch they want to go down. Or it might be a chain of questions related to the branch. 

```

{-| Find out if a user wants to record details of pizza. If so, send the user to questions about pizza.
-}
askPizza : Model -> Interviewer Model (Html Msg)
askPizza model = case model.pizzaChoice of 
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

This could be extended as a chain of questions, like

Continue model
|> ask toppings
|> ask size
-} 
askPizzaDetails : Model -> Interviewer Model (Html Msg)
askPizzaDetails model = case model.pizza of 
    Answered _ _ -> Continue model
    Unanswered txt f err -> Ask (div [] 
        [ input [placeholder "pizza deets", value txt, onInput UpdatePizza] []
        , text err
        , button [onClick SavePizza] [text "Continue"]
        ])




```


4. Collecting Lists

To collect a list of values of type `Question a`, 

5. Showing the questions. 

These 

6. Producing documents. 

Inquisimin-Elm only runs the interview and collects data, so producing documents is outside its scope. However, if you want to produce a document using data inquisimin has collected, you may send the data via an api call to a third party document-generating service. 
