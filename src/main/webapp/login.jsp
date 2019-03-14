<%@page import="java.net.*"%><%--
--%><%@page import="java.nio.charset.StandardCharsets"%><%--
--%><%@page import="org.foo.servlet.CookieCutter"%><%--
--%><%@page import="java.io.*"%><%--
--%><%@page import="java.util.*"%><%--
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
--%><%--
--%><%
	request.getServletContext().log("login.jsp");

	if ("1".equals(request.getParameter("error"))) {
		request.setAttribute("login_error", true);
	} else {
	    // The initial render of the login page
		String uuid = getCookieValue(request, COOKIE_NAME);
		if (uuid != null) {
			Map.Entry<String,String> creds = rememberMeServiceFind(request, uuid);
			if (creds != null) {
				String username = creds.getKey();
				String password = creds.getValue();
				jSecurityCheck(request, response, username, password);
				return; // going to redirect here again if login error
			}
		}
	}

	String username = request.getParameter("j_username");
	if (!isBlank(username)) {
		String password = request.getParameter("j_password");
		Map.Entry<String,String> creds =
			new AbstractMap.SimpleEntry<String,String>(username,password);
		if ("on".equals(request.getParameter("remember_me"))) {
			String uuid = UUID.randomUUID().toString();
			addCookie(response, COOKIE_NAME, uuid, COOKIE_AGE); // Extends age.
			rememberMeServiceSave(request, uuid, creds);
		}
		jSecurityCheck(request, response, username, password);
		return;
	}
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
			<h1>Please sign in</h1>
			<label for="j_username">Login</label>
			<input id="j_username" name="j_username" type="text" value="client"/>
			<label for="j_password">Password</label>
			<input id="j_password" name="j_password" type="password">
			<label for="remember_me">Remember me</label>
			<input type="checkbox" id="remember_me" name="remember_me" <c:if test="${param.remember_me == 'on' || empty param.submit}"> checked="checked"</c:if>/>
			<input type="submit" name="submit"/>
		</form>
		<c:if test="${login_error}">
			<p><b>Login Error</b></p>
		</c:if>
	</body>
</html><%--
--%><%--
--%><%--
--%><%@include file="/WEB-INF/jspf/loginutil.jspf" %><%!

	/** Using "j_security_check" instead of request.login() lets the container restore
	 * not only the original address, but the method and the POST data
	 */
	public static void jSecurityCheck(HttpServletRequest request, HttpServletResponse response, String username, String password) throws Exception {
		Map<String, String> formParams = new HashMap<String, String>();
		formParams.put("j_username", username);
		formParams.put("j_password", password);
		byte[] postData = getDataString(formParams).getBytes( StandardCharsets.UTF_8 );
		int postDataLength = postData.length;
		// TODO: detect container http listener has SSL/TLS enabled
		// (request.isSecure() unreliable due to possible offload) 
		String s = "http://" + request.getLocalAddr() + ":" + request.getLocalPort()
			+ request.getContextPath() + "/j_security_check";
		HttpURLConnection conn = (HttpURLConnection)new URL(s).openConnection();
		conn.setDoOutput(true);
		conn.setUseCaches(false);
		conn.setInstanceFollowRedirects(false);
		conn.setRequestMethod("POST");
		
		String PROP = "sun.net.http.allowRestrictedHeaders";
		if (!"true".equals(System.getProperty(PROP))) {
		    request.getServletContext().log("must set to true: " + PROP);
		}
		conn.setRequestProperty("Host", request.getHeader("Host"));
		
		conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
		conn.setRequestProperty("Content-Length", Integer.toString(postDataLength ));
		conn.setRequestProperty("charset", "utf-8");
		conn.setRequestProperty("Cookie", request.getHeader("Cookie"));
		OutputStream wr = conn.getOutputStream();
		try {
			wr.write(postData);
		} finally {
		    wr.close();
		}
		int code = conn.getResponseCode();
		String location = null;
		if (code == 301 || code == 302 || code == 303 || code == 307 || code == 308) {
			location = conn.getHeaderField("Location");
			if (location != null) {
			    // There's no way to detect login success or failure
			    // The Location can be either the login page or the original page address.
			    // In the latter case it may still serve the login page again.
				String newcook = conn.getHeaderField("Set-Cookie");
				if (newcook != null) {
					// response.setHeader("Set-Cookie", newcook);
					CookieCutter cc = new CookieCutter();
					cc.addCookieField(newcook);
					for (Cookie c : cc.getCookies()) {
						response.addCookie(c);
					}
				}
				response.sendRedirect(location);
				return;
			}
		}
		throw new ServletException("Unexpected j_security_check response " + code + " Location: " + location);
	}

	private static String getDataString(Map<String, String> params) throws UnsupportedEncodingException{
	    StringBuilder result = new StringBuilder();
	    boolean first = true;
	    for(Map.Entry<String, String> entry : params.entrySet()){
	        if (first)
	            first = false;
	        else
	            result.append("&");
	        result.append(URLEncoder.encode(entry.getKey(), "UTF-8"));
	        result.append("=");
	        result.append(URLEncoder.encode(entry.getValue(), "UTF-8"));
	    }    
	    return result.toString();
	}

	%><%--
--%><%--
--%><%--
--%>
