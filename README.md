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

To implement the "Stay Logged In" feature we save the credentials from the submitted login form in the servlet context attribute (for now). Unlike in the SO answer above, the password is not hashed, because only certain setups accept that (Glassfish with a jdbc realm). The persistent cookie is associated with the credentials.

The flow is the following:
* Get forwarded/redirected to the login form
* If we're served as the `<form-error-page>` then render the form and the error message
* Otherwise, if some credentials are submitted, then store them and call `/j_security_check` and redirect to the outcome (which might be us again)
* Otherwise, if the cookie is found, then retrieve the associated credentials and continue with `/j_security_check`
* If none of the above, then render the login form without the error message

The code for `/j_security_check` sends a POST request using the current `JSESSIONID` cookie and the credentials either from the real form or associated with the persistent cookie. 

Most of the code is inside JSP scriptlets for easier hot swap during the initial phase of the development. It can be easily moved into a servlet.

## TODOs

Set the `Path=<contextRoot>` for the cookie

Temporarily store password in session and convert to cookie in a global filter. This will allow to store only the successfully used credentials instead of deleting the them while serving the error page

Detect container HTTP listener has SSL/TLS enabled (`request.isSecure()` unreliable due to possible offload). Possibly use a custom `SSLSocketFactory` tweaked for "trust all" to access the HTTP listener on local host.

Possibly, switch to the Apache HTTP Client, because `HttpURLConnection` does not allow overriding the `Host:` header and this is important, if you have virtual servers. Alternatively, use a custom `java.net.Proxy` for both "trust-all" SSL Socket and that connects the virtual server URL to the real IP address.

Encrypt and store the credentials on disk.
