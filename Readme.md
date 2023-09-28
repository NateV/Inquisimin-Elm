# Inquisimin Elm


Minimal guided interviews with Elm. 

There are lots of great tools for setting up guided interviews. Often these tools come with a lot of other great features too. Sometimes I don't want all those other features. Instead I just want a guided interview that runs in the browser. It asks some questions, collects some data, and shows something to the user based on the user's data. Thats it. Inquisimin aims to help with that limited task. If you need more features, you can use Inquisimin to collect data that you then send to some other tool.


## Getting Started
Inquisimin-Elm provides tools for creating minimal guided interviews in an Elm application. To start a guided interview, start with a new Elm project. 

1. Model. 

Create a Model type. A Model holds the application's state in an Elm app. Our model type will include members of type `Question a`. 

A `Question a` is a type that:

* stores text from html inputs, while the user is writing it. 
* tracks whether the question is compeleted or not 
* stores a parser that can map the stored String to whatever the Question's goal type is. These parsers should return a value of the type `Valid a` for a `Question a`, or an `Error String` if the `Question`'s parser could not parse the result. 
* stores an error message if the current stored text can't be parsed to `a`.

Here's an example parser that requires user inputs to be integers:

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



2. Presenting questions to the user

To present a question to user, you'll write a function of type `Model -> Interviewer Model (Html Msg)`. This function has two jobs.

First, it checks the `Model` to see if it is time to ask the question. Often this means checking if a certain Question in the Model is `Unanswered`.

Second, if it _is_ time to ask the question, the function evaluates to an `Html Msg` chunk of html with inputs for the user to enter data.

Here's an example:


```elm

```

These 'Question Views' are mostly just regular views in an elm application with the extra case-checking. That means you can ask multiple questions in each one, or stick to a single `Question.` 


2. The Interview

An Interview links together your Model of Questions and the Question Views that let the user answer the questions. 

Create an interview with the `Interview model msg` type. An `Interview` needs three peices. 

First, the Interview needs the model on which it will operate.

Second, it needs the interview to run. An interview is a chain of `Model -> Interviewer Model (Html Msg)` functions. Combine them with 
`ask `, as in 

```elm
Continue model 
|> ask questionView1
|> ask questionView2
```

Each of these `questionView` functions has type `Model -> Interview Model Msg`.  

Finally, you must add a function with the type `Interviewer Model (Html Msg) -> Html Msg`. This function will always display at the end of the interview, if no other question needs to get asked. You can think of it either as the 'termination' of the interview, or as a 'catch-all' that will display if nothing else does.


3.  Branching questions

We can handle branching questions with the following technique. 

If the branch will depend on a user's explicit choice, add a property to the Model that tracks which branch a user is going down. For example 

```
type WantsCake = Yes | No | Unknown 
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
    -- Skip asking any pizza questions and continue with the rest of the interview.
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

To collect a list of values of type `Question a`, add an item of type `Collection a` to your model. This will store a dictionary of `Dict Int (Question a)` values as well as a flag indicating if the list is `Complete` or not.  

`mkCollection` helps create a new collection. Pass it the `String -> Valid a` parser the underlying `Question a` values need.

Views will use the `Complete` flag to determine if the interview should ask the user for more items in the collection.

```elm
collectColors : Model -> Interviewer Model (Html Msg)
collectColors model = case (getComplete model.colors) of
    Complete -> Continue model
    Incomplete -> Ask (collectColors_ model)
```

Then `collectColors_` presents the html to the user. The helper `collectColor` gives a snippet html that can update a single stored `Color` in the model's `Collection`. `collectColors_` renders all the needed one-color snippets and adds buttons for adding more colors or finishing the collection. 

```

collectColors_ : Model ->  (Html Msg)
collectColors_ model = div [] (
    (List.map collectColor (getQuestions model.colors) ++ 
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


```

5. Revisiting questions.

Not implemented yet.


5. Displaying the results.

Every Interview needs to end with a 'catchall' view that will always appear. It has the type `Interviewer model (Html msg) -> Html msg)`. You can use this catchall to display the final 'results' of the interview, or to dispatch actions such as network calls to use the interview's data to generate a document.

6. Producing documents. 

Inquisimin-Elm only runs the interview and collects data, so producing documents is outside its scope. However, if you want to produce a document using data inquisimin has collected, you may send the data via an api call to a third party document-generating service. 
