# rememberme
Implement Stay Logged In in java EE 7 without custom Login Module

Inspired by the SO answer "How to implement “Stay Logged In” when user login in to the web application" https://stackoverflow.com/a/5083809/447503

The aim is to be functional in any compliant servlet container and not break the existing security settings in web.xml or java annotations.

## Quick start

* `mvn jetty:run`
* http://localhost:8080/rememberme/
* client/client

## Features

* Automatic login when browser is reopened
* Logout all devices when user changes password
* Honor security annotations like `@HttpConstraint` as well as `<security-constraint>` tags in `web.xml`
* Redirect to the initially requested web page after submitting the login form
* Restore the initial HTTP method and POST data after logging in
* Container-agnostic (trying to be)
* Tested on `Glassfish 4.1.2`, `Tomcat 8.0`, `Jetty 9.4.15.v20190215`

## Implementation details

Instead of calling `request.login()` we establish a new TCP connection to our HTTP listener and post the login form to the `/j_security_check` address. This allows the container to redirect us to the initially requested web page and restore the POST data (if any). Trying to obtain this info from a session attribute or `RequestDispatcher.FORWARD_SERVLET_PATH` would be container-specific.

We don't use a servlet filter for automatic login, because containers forward/redirect to the login page BEFORE the filter is reached.

The dynamic login page does all the job, including:
* actually rendering the login form
* accepting the filled form
* calling `/j_security_check` under the hood
* displaying login errors
* automatic login
* redirecting back to the initially requested page

To implement the "Stay Logged In" feature we save the credentials from the submitted login form in the servlet context attribute (for now). Unlike in the SO answer above, the pasword is not hashed, because only certain setups accept that (Glassfish with a jdbc realm). The persistent cookie is associated with the credentials.

The flow is the following:
* Get forwarded/redirected to the login form
* Check if we're served as the `<form-error-page>`
* If not, check if some credentials are submitted
* 

sent by browser are 


The containers don't allow filters on 

Most of the code is inside JSP scriptlets for easier hot swap during the initial phase of the development. It can be easily moved into a servlet.
