# Concept behind Inquisimin

One of this project's goals is to describe, from a functional perspective, what a guided interview _is_. Or at least what a functional guided interview does and how, if we want to avoid being [Essentialist](https://en.wikipedia.org/wiki/Essentialism) about it. If I have a clear understanding of the pieces of a guided interview tool, hopefully it will be more straightforward to implement guided interviews in whichever language happens to be convenient for a particular project. We may also learn some features of 'guided interviews' that are interesting or applicable to other kinds of problems. 

A guided interview is an interface that presents a user with a sequence of questions. The questions that are asked may depend on answers to prior questions (interviews have branches). The number of times that questions are asked may also depend on a user's responses. An interview might collect all the names of a users' cats, which may vary from zero to ... too many. An interview always ends. And at the end, some blob of data has been collected. Software might use this data to fill out a document template, give the user some advice ("Your answers suggest you might like having another cat"), or something else.

With Inquisimin, we are describing this kind of guided interview as a function with three parts:
1. **Interview State**: There is some data structure that stores whatever it is this interview is about. For a typical guided interview, this will be something like a key value store.
2. **A library of state-modifying actions**: There is a library of functions that modify the state. And they do this modification in some kind of context or effect such as user interactions. Typically these define the questions that get presented to a user.
3. **A mapping from State to Actions**: There is some function for mapping the interview's current state to a function in the library. This function should be [total](https://en.wikipedia.org/wiki/Partial_function) so the interview always knows what to do with the interview's state.

The state-modifying questions are typically questions for the user. 

Framed this way, a typical guided interview works as follows:
 1. We start with an empty interview state. 
 2. The "State-to-Action" mapping determines that this value of the State corresponds to a Question for the user called "Question 1". Thus the interview, in this moment, evaluates to a user-interaction that poses "Question 1" to the user.
 3. When the user answers Question 1, the state is updated to include the user's response. 
 4. The "State-to-Action" now determines that the current value of the State corresonds to a different Question, "Question 2". 
 5. And so on, until the "State-to-Action" mapping determines the interview maps to some final effect, such as displaying the final results of the guided interview to the user.

 In this way the user steps through questions in the guided interview. The "order" of the questions happens as a consequence of how the "State-to-Action" function maps different possible states to state-modifying functions. 

## Styles of Interviews

We can write a guided interview with just this framework. We need some `Model` type to hold the state of the interview; we need functions that fill in parts of the `Model`; and we need a map from the `Model`'s various possible states to user-facing forms of the type `Html Msg`. The example [BareBonesInterview](examples/BareBones.elm) works like this.

There are a few limitations of this pattern. The mapper in an interview this way can become too verbose. Also, the mapping function does not give many clues about how the interview will actually behave for the user. What order of questions will the user experience? Under what circumstaces will different questions get skipped or asked? Which questions depend on the values of others? 

I've found a couple different "styles" for "State-to-Action" mappers (and a few related helper functions) that lead to different common kinds of interviews.

### Explicitly ordered

The modules [Inquisimin](src/Inquisimin.elm) and [DictModel](src/DictModel.elm) support styles in which the programmer describes the interview's questions in the order they should appear. These modules use a type `Interview viewtype model` and a related function `ask` to make it possible to write out an interview's questions in the order they should appear:

```elm
    m 
    |> ask firstQ
    |> ask secondQ
    |> ask thirdQ
```

`Inquisimin` supports branching interview paths and collecting lists of items. `DictModel` supports branching paths, but does not (yet) support collecting lists of items. 

### Dependency ordered

The module [DependencyModel](src/DependencyModel.elm) allows the user to define a `Library` of questions that might be asked and a set of requirements for the interview. Questions for the user might specify their own requirements. This model will trace the dependencies of a question and ask the precursor questions before returning to the original requirements. 

## Implications for Testing

There is an interesting (to me, at least) consequence of this conceptual approach to guided interviews. The state-modifying questions do not have to be user interactions. The user interactions 'wrap' the state in a typical question. We can replace the user interactions with a different kind of wrapper that does not need user input. Thus, we can write state-modifying questions that mock user input in a straightforward way. 

For example, instead of user interaction that asks for a user's name:

```elm
askfname : Model -> Interviewer Model (Html Msg)
askfname model = case model.interviewState.firstName of 
    Answered _ _ _ -> Continue model
    Unanswered txt _ err  -> Ask (div [] 
        [ text "Name?"
        , input [placeholder "fname", value txt, onInput UpdateName] [] 
        , text err
        , button [onClick SaveName] [text "Continue"]
        ])
```

A test could skip the user action and modify the model directly:

```elm
mockaskname model = Continue { model | name = "mocked name" }
```
