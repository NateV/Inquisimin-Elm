# Concept behind Inquisimin

One of this project's goals is to describe, from a functional perspective, what a guided interview _is_. Or at least what one does and how, if we want to avoid being [Essentialist](https://en.wikipedia.org/wiki/Essentialism) about it. If I have a clear understanding of the pieces of a guided interview tool, hopefully it will be more straightforward to implement guided interviews in whichever language happens to be convenient for a particular project. We may also learn some features of 'guided interviews' that are interesting or applicable to other kinds of problems. 

A guided interview is an interface that presents a user with a linear sequence of questions. The questions that are asked may depend on answers to prior questions (interviews have branches). The number of times that questions are asked may also depend on a user's responses. An interview might collect all the names of a users' cats, which may vary from zero to ... too many. An interview always ends. And at the end, some blob of data has been collected. Software might use this data to fill out a document template, give the user some adice ("Your answers suggest you might like having another cat")

With Inquisimin, we are describing this kind of guided interview as a function with three parts:
1. There is some data structure that stores whatever it is this interview is about. For a typical guided interview, this will be something like a key value store.
2. There is a library of functions that modify the state. And they do this modification in some kind of context or effect such as user interactions. Typically these define the questions that get presented to a user.
3. There is some function for mapping the data structure to a function in the library. This function should be [total](https://en.wikipedia.org/wiki/Partial_function) so the interview always knows what to do with the interview's state.

The state-modifying questions are typically questions for the user. The question presents some interface to the user, and uses the user's inputs to modify the state. Now the guidedinterview looks up which state-modifying question is the appropriate one to show. In this way the guided steps through questions in the guided interview. The "order" of the questions happens as a consequence of how the interiview maps different possible states to state-modifying functions. 

## Types of Interviews


## Styles of Mappers

### Explicitly ordered

### Dependency ordered

## Implications for Testing

The state-modifying questions do not have to be user interactions. The user interactions 'wraps' the state in a typical question. We can replace the user interactions with a different kind of wrapper that does not need user input. Instead we can write state-modifying questions that mock user input in a straightforward way. 
