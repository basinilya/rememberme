# rememberme
Implement Stay Logged In  in java EE 7 without custom Login Module

Inspired by the SO answer "How to implement “Stay Logged In” when user login in to the web application" https://stackoverflow.com/a/5083809/447503

The aim is to be functional in any compliant servlet container and not break the existing security settings in web.xml or java annotations.

## Quick start

* `mvn jetty:run`
* http://localhost:8080/rememberme/
* client/client

## Features

* Automatic login when browser is reopened
* Honor security annotations like `@HttpConstraint` as well as `<security-constraint>` tags in `web.xml`
* Redirect to the initially requested web page after submitting the login form
* Restore the initial HTTP method and POST data after logging in


