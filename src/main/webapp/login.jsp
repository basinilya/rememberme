<%@page import="java.util.*"%><%--
--%><%@page contentType="text/html" pageEncoding="UTF-8"%><%--
--%><%--
--%><%--
--%><%--
--%><%--
--%><%@ taglib prefix = "c" uri = "http://java.sun.com/jsp/jstl/core" %><%--
--%><%@ taglib prefix = "fmt" uri = "http://java.sun.com/jsp/jstl/fmt" %><%--
--%><%@ taglib prefix = "fn" uri = "http://java.sun.com/jsp/jstl/functions" %><%--
--%><%--
--%><%--
--%><%--
--%><%@include file="/WEB-INF/jspf/loginutil.jspf" %><%!

    private static volatile Boolean hashSupported = null;

    public static boolean tryHashLogin(HttpServletRequest request, Map.Entry<String,String> creds) {
	System.out.println("hashSupported: " + hashSupported);
	String username = creds.getKey();
	String password = creds.getValue();
	if (!Boolean.FALSE.equals(hashSupported)) {
	    String hashedPass = hash(password);
	    if (tryLogin(request, username, hashedPass)) {
		hashSupported = Boolean.TRUE;
		creds.setValue(hashedPass);
		return true;
	    } else if (hashSupported != null) {
		return false;
	    }
	}
	if (tryLogin(request, username, password)) {
	    hashSupported = Boolean.FALSE;
	    return true;
	}
	return false;
    }

    public static boolean tryLogin(HttpServletRequest request, String username, String password) {
	try {
	    request.login(username, password);
	    return true;
	} catch (ServletException e) {
	    return false;
	}
    }
%><%
    System.out.println("login.jsp");
    String originalUri = request.getParameter("original_uri");
    if (isBlank(originalUri)) {
        originalUri = (String) request.getAttribute(RequestDispatcher.FORWARD_SERVLET_PATH);
        if (originalUri == null) {
            originalUri = "/";
        } else {
            // forwarded here by container
            String uuid = getCookieValue(request, COOKIE_NAME);
            if (uuid != null) {
                Map.Entry<String,String> creds = rememberMeServiceFind(request, uuid);
                if (creds != null) {
                    String username = creds.getKey();
                    String password = creds.getValue();
                    if (tryLogin(request, username, password)) {
                        System.out.println("forward: " + originalUri);
                        RequestDispatcher dispatcher = getServletContext().getRequestDispatcher(originalUri);
                        dispatcher.forward(request,response);
                        return;
                    }
                }
            }
        }
    }
    String username = request.getParameter("j_username");
    if (!isBlank(username)) {
        String password = request.getParameter("j_password");
	Map.Entry<String,String> creds =
	    new AbstractMap.SimpleEntry<String,String>(username,password);
        if (!tryHashLogin(request, creds)) {
            request.setAttribute("login_error", true);
	} else {
            if ("on".equals(request.getParameter("remember_me"))) {
                String uuid = UUID.randomUUID().toString();
                addCookie(response, COOKIE_NAME, uuid, COOKIE_AGE); // Extends age.
                rememberMeServiceSave(request, uuid, creds);
            }
            
            // send 302 redirect
            if (originalUri.startsWith("/")) {
                originalUri = originalUri.substring(1);
            }
            if (originalUri.isEmpty()) {
                originalUri = "."; // Tomcat 8 sends empty Location by default
            }
            response.sendRedirect(originalUri);
            return;
        }
    }
    if ("1".equals(request.getParameter("error"))) {
	request.setAttribute("login_error", true);
    }
    request.setAttribute("original_uri", originalUri);
%><%--
--%><!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Login Page</title>
    </head>
    <body>
        <c:url value="${pageContext.request.servletPath}" var="url"/>
        <%--  --%>
        <form method="post" action="${fn:escapeXml(url)}">
            <h1>7 Please sign in</h1>
            <label for="j_username">Login</label>
            <input id="j_username" name="j_username" type="text"/>
            <label for="j_password">Password</label>
            <input id="j_password" name="j_password" type="password">
            <input name="original_uri" type="hidden" value="${fn:escapeXml(original_uri)}"/>
            <label for="remember_me">Remember me</label>
            <input type="checkbox" id="remember_me" name="remember_me" <c:if test="${param.remember_me == 'on' || empty param.submit}"> checked="checked"</c:if>/>
            <input type="submit" name="submit"/>
        </form>
        <c:if test="${login_error}">
            <p><b>Login Error</b></p>
        </c:if>
    </body>
</html>
