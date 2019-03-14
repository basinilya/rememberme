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
--%><%@include file="/WEB-INF/jspf/loginutil.jspf" %><%--
--%><%
    String uuid = getCookieValue(request, COOKIE_NAME);
    if (uuid != null) {
	getRememberMeMap(request).remove(uuid);
	removeCookie(response, COOKIE_NAME);
    }

    request.getSession().invalidate();
    System.out.println("logged out");
%><%--
--%><!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>RememberMe Logout</title>
    </head>
    <body>
        <h1>Logged Out Successfully</h1>
		<p>
        <a href=".">Index...</a>
		</p>
		<p>
	        <a href="static/unrestricted.html">Unrestricted...</a>
		</p>
    </body>
</html>
