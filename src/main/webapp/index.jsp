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
--%><%
%><%--
--%><!DOCTYPE html>
<!--
-->
<html>
    <head>
        <title>RememberMe Index</title>
        <meta charset="UTF-8">
    </head>
    <body>
	<%@include file="/WEB-INF/jspf/heading.jspf" %>
        <h1>Index</h1>
	<p>
        <a href="restricted/page.jsp">Restricted...</a>
	</p>
	<p>
        <a href="static/unrestricted.html">Unrestricted...</a>
	</p>
    </body>
</html>
