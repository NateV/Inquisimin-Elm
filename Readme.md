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
|> ask question1
|> ask question2
```

Add an `Html Msg` at the end which will always display at the end of the interview.

3.  Branching questions

We can handle branching questions. with the following technique. 

Create a question for the 'split' of a branch, and a place in the Model to store the answer to the question about which direction the branch should go. 

Then use a case statement on that user choice.

4. Collecting Lists

To collect a list of values of type `Question a`, 

5. Producing documents. 

Inquisimin-Elm only runs the interview and collects data, so producing documents is outside its scope. However, if you want to produce a document using data inquisimin has collected, you may send the data via an api call to a third party document-generating service. 
