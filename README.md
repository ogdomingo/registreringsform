# Registreringsform

This is a sign up form that checks for allowed characters, and contacts the backend asynchronously and informs the user whether it is available.

## Demo

[![Watch the project demo](https://img.youtube.com/vi/ZGy_glxa4z4/0.jpg)](https://www.youtube.com/shorts/ZGy_glxa4z4)

## Tools & Technologies

* Swift
* Combine
* Firebase SDK

## Results and Next Steps

I am happy about how the implementation turned out; I've learned a lot about how Combine functions.

There is room for improvement of course. The user could be informed why the username is not valid (invalid characters or unavailable username) via a text view under the form. Then there is the possibility of creating Combine operator pipelines for the email and password too, and using CombineLatest to enable the signup button.
