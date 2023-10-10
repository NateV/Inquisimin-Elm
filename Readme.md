# Inquisimin Elm

**Early, early days of an experiment; a small plant I plan to grow slowly. Feedback welcomed**


Currently broken, because I'm giving non-DictModel interviews the ability to track history. Should I just do the kind of brutal insertion of `model.interViewState` everywhere, or should ... `ask` know to just pass the `model.interviewState` to QuestionViews instead of passing the whole model? If I do that, I need to fix DictModel's which don't work like that. Should they, or should there be separate `ask` functions for DictModel interviews and TypedModel interviews? 

[<img alt="alt_text" width="100px" src="Inquismin Logo.png" />](https://github.com/NateV/Inquisimin-Elm)

Minimal guided interviews with Elm. 

There are lots of great tools for setting up guided interviews. Often these tools come with a lot of other great features too. Sometimes I don't want all those other features. Instead, I just want a guided interview that runs in the browser. It asks some questions, collects some data, and shows something to the user based on the user's data. Thats it. 

Inquisimin aims to help with this limited task. If you need more features, you can use Inquisimin to collect data that you then send to some other tool. Inquisimin handles only the guided interview, and you can plug it into more complicated applications however you like. 


## New to Elm?

Inquisimin is a library to help write guided interivews in the Elm language. If you are new to Elm, I recommend visiting the [Elm Introduction](https://guide.elm-lang.org/)

## Getting Started with a DictModel Interview

The `DictModel.elm` module provides helpers for creating a very simple interview quickly. We need three things: 
1. A `main` function, like in any other Elm app.

2. Fuctions that define the questions we want to ask the user.

3. An `interview` that desribes how these questions should get asked. 

DictModel interviews can handle branching paths. (See [this example](examples/BranchingDictModel.elm))

DictModel interviews have other limitations. They currently don't support asking a user for an unknown number of some repeated item. (A `Collection` in the more comlicated non-DictModel interviews). If you are using the helpers for making questions for users, these views will all create HTML views, so you cannot use Elm-UI instead. These interviews also do not currently support input validation. If these restrictions don't work for you, you'll need to go beyond `DictModel` interviews. We'll see in this section how `DictModel` interviews work, and then we'll see how to go beyond them in the next section.  


In a DictModel interview, the `main` function is an ordinary `main` Elm function. The initial model is an empty Dictionary. The `update` method is `updateDictModel` from `DictModel.elm`. The view is `mkDictModelInterviewView`, also from `DictModel.Elm`. You need to write your own `interview` function, though, so we'll define that next.

Here is an example `main` function that will run in Elm's browser sandbox. If you want to run the interview in `Browser.element` or another Program with side effects, modify your main function to hande those effects outside of the interview. 

TODO provide an example with `Browser.element`

```elm
main : Program () Model Msg
main = Browser.sandbox 
    { init = mkDictModel 
    , update = updateDictModel
    , view = mkDictModelInterviewView interview
    }
```

Next, we will use helpers from `DictModel.elm` to make the questions our interview will present to users. We'll use `mkTextQuestionView` for this purpose. This function needs a string key to identify this question in the interview's model, and a friendly label to present the question to the user.

```elm
askfname : Model -> Interviewer (Model) (Html Msg) 
askfname model = mkTextQuestionView "firstname"  "First Name" model
```

You can write these functions in point-free style to be extra concise:

```elm
cattype : Model -> Interviewer (Model) (Html Msg)
cattype = mkTextQuestionView "cattype" "Cat Type"
```

Finally, the last piece of our `DictModel` interivew is the `interview` function itself. This function takes the interview's Model and creates a value of the `Interview` type. The interview type needs 

1. The model
2. A function that lays out the order in which the interview's questions should be asked
3. A final function that will display to the user when the rest of the interview is complete. 

This might look like

```elm
interview : Model -> Interview Model (Html Msg)
interview m = Interview m
    (\m_ -> m_
        |> ask askfname
        |> ask cattype)
    displayDictModel 
```

In this example, the Model `m` is the DictModel created in `init`. The function `displayDictModel` is a helper from `DictModel.elm`, and it just displays the data the interview has collected into the Model. 

The middle component needs a little explanation:

```elm
\m -> m_ 
    |> ask askfname
    |> ask cattype
```

This function describes the steps of the interview. First the interview will ask the `askfname` question, followed by then the `cattype` question. These functions, `askfname` and `cattype`, lets call them "QuestionViews". Each one decides whether it needs to be asked, and then provides the user interface for asking the question. The function `ask` binds together "QuestionView" functions such as these. This way, we can write interviews by describing their steps in what I hope is a natural-feeling syntax. [^Either]

[^Either]: If you are familiar with the Either monad, `ask` and the QuestionViews basically work like the Either Monad. 

Now we've got everything we need for a simple guided interview running in the browser. We'll ask a series of questions to the user and present them with the results. From there, other parts of an application can do something else with that collected data.


## Complexity beyond what DictModel can handle: TypedModel Interviews

Its likely you may want to do more than DictModel can manage. You may want to style your interview differently, introduce branching pathways, or ask users for multiple instances of some items (e.g, a list of their favorite foods). We'll say goodbye to DictModel now, and see how we can use Inquisimin for a more customized guided interview.

1. Model. 

We'll start with a Model type that is more descriptive than an empty dictionary. An interview's modeltype will be a product type with members of type `Question a`. 

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

To present a question to user, you'll write a function of type `Model -> Interviewer Model viewtype`. This function has two jobs.

First, it checks the `Model` to see if it is time to ask the question. Often this means checking if a certain Question in the Model is `Unanswered`.

Second, if it _is_ time to ask the question, the function evaluates to an `viewtype` chunk of html with inputs for the user to enter data. The `viewtype` type variable is for the type of the user interface your application is using, probably `Html Msg` or `Element Msg`. (But if you find other interesting things to do with this type variable, let me know!) 

Here's an example:


```elm
askfname : Model -> Interviewer Model (Html Msg)
askfname model = case model.firstName of 
    -- If the question has been Answered, we just pass along the model to whomever might 
    -- want to ask a later question
    Answered _ _ _ -> Continue model
    -- If the question has not been Answered, then lets deliver an Html Msg 
    -- that should get presented to the user.
    Unanswered txt f err  -> Ask (div [] 
        [ input [placeholder "fname", value txt, onInput UpdateName] [] 
        , text err
        , button [onClick SaveName] [text "Continue"]
        ])
```

These 'QuestionViews' are mostly just regular views in an Elm application with the extra case-checking to figure out if it is time to ask a particular question view. That means you can ask multiple questions in each one, or stick to a single `Question.` 


2. The Interview

An Interview links together your Model of Questions and the Question Views that let the user answer the questions. 

Create an interview with the `Interview model msg` type. An `Interview` needs three peices. 

First, the Interview needs the model on which it will operate.

Second, it needs the interview to run. An interview is a chain of `Model -> Interviewer Model viewtype` functions. Combine them with 
`ask `, as in 

```elm
Continue model 
|> ask questionView1
|> ask questionView2
```

Each of these `questionView` functions has type `model -> Interview model viewtype`.  

Finally, you must add a function with the type `Interviewer model viewtype -> viewtype`. This function will always display at the end of the interview, if no other question needs to get asked. You can think of it either as the 'termination' of the interview, or as a 'catch-all' that will display if nothing else does.


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

To collect a list of values of type `Question a`, add an item of type `Collection a` to your model. This will store a dictionary of `Dict Int (Question a)` values as well as a flag indicating if the list is `Complete` or not. The collection's `Complete` state is distict from whether the question in the collection are `Answered` or still `Unanswered`.  

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

Currently, we can 'go back' to questions in a DictModel interview. The DictModel has a 'Go Back' message that will return the user to the previously answered question. 

There is not currently a method for doing that if you're not using a DictModel interview. Non-dict-model interviews also do not have unique String names for questions. Its making me wonder if the DictModel should be the only way to track state in inquisimin.

6. Displaying the results.

Every Interview needs to end with a 'catchall' view that will always appear. It has the type `Interviewer model (Html msg) -> Html msg)`. You can use this catchall to display the final 'results' of the interview, or to dispatch actions such as network calls to use the interview's data to generate a document.

7. Producing documents. 

Inquisimin-Elm only runs the interview and collects data, so producing documents is outside its scope. However, if you want to produce a document using data inquisimin has collected, you may send the data via an api call to a third party document-generating service. 

The example, "InterviewWithXFDF.elm", demonstrates another interesting possibility. This Inquisimin interview generates an XFDF file for filling in a PDF form's fillable fields. Many desktop utilies can import form data from an XFDF into a PDF. With this approach, the Inquisimin interview does not need any IO effects outside of the `Browser.sandbox` to fill in a PDF form. The user still has to import the data, but this might even be made invisible to the user if the user's desktop PDF reader automatically merges XFDF files with their PDF counterparts.

8. Persistence

Inquisimin runs locally in the browser. It doesn't have any mechanism built-in for persisting the interview data. You might consider a `Cmd` that serializes your model and sends it out to be stored in some way, perhaps in browser storage or a cookie.
