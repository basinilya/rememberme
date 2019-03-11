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
---%><%!
    
    public static final String COOKIE_NAME = "rememberme";

    public static final int COOKIE_AGE = 30 * 86400;
    
    /** Helps when just "?a=b" turns into ";jsessionId=blah?a=b" */
    public static String getOriginalRequestURI(HttpServletRequest request) {
        String uri = (String) request.getAttribute(RequestDispatcher.FORWARD_SERVLET_PATH);
        if (uri == null) {
            uri = request.getServletPath();
        }
        return uri;
    }

    private static boolean isBlank(String s) {
        return s == null || s.isEmpty();
    }

    public static void addCookie(HttpServletResponse response, String name, String value, int maxAge) {
        Cookie cookie = new Cookie(name, value);
        cookie.setPath("/");
        cookie.setMaxAge(maxAge);
        response.addCookie(cookie);
    }

    public static Map.Entry<String,String> rememberMeServiceFind(HttpServletRequest request, String uuid) {
        return getRememberMeMap(request).get(uuid);
    }

    public static void rememberMeServiceSave(HttpServletRequest request, String uuid,
    Map.Entry<String,String> creds
    ) {
        getRememberMeMap(request).put(uuid, creds);
    }

    public static Map<String, Map.Entry<String,String>> getRememberMeMap(HttpServletRequest request) {
        Map<String, Map.Entry<String,String>> rememberMeMap =
            (Map<String, Map.Entry<String,String>>)request.getServletContext().getAttribute("rememberMeMap");
        if (rememberMeMap == null) {
            rememberMeMap = new HashMap<String, Map.Entry<String,String>>();
            request.getServletContext().setAttribute("rememberMeMap", rememberMeMap);
        }
        return rememberMeMap;
    }

    public static String getCookieValue(HttpServletRequest request, String name) {
        Cookie[] cookies = request.getCookies();
        if (cookies != null) {
            for (Cookie cookie : cookies) {
                if (name.equals(cookie.getName())) {
                    return cookie.getValue();
                }
            }
        }
        return null;
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
                    boolean ok = false;
                    try {
                        request.login(username, password);
                        ok = true;
                    } catch (ServletException e) {
                        //
                    }
                    if (ok) {
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
        boolean ok = false;
        try {
            request.login(username, password);
            ok = true;
        } catch (ServletException e) {
            request.setAttribute("login_error", true);
        }
        if (ok) {
            if ("on".equals(request.getParameter("remember_me"))) {
                String uuid = UUID.randomUUID().toString();
                addCookie(response, COOKIE_NAME, uuid, COOKIE_AGE); // Extends age.
                rememberMeServiceSave(request, uuid, new AbstractMap.SimpleEntry<String,String>(username,password));
            }
            // TODO: create cookie and save creds
            
            // send 302 redirect
            if (originalUri.startsWith("/")) {
                originalUri = originalUri.substring(1);
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
