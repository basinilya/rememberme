// Copyright (c) 1995-2019 Mort Bay Consulting Pty. Ltd.
package org.foo.servlet;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.logging.Level;
import java.util.logging.Logger;

import javax.servlet.http.Cookie;


/* ------------------------------------------------------------ */
/**
 * Cookie parser
 * <p>
 * Optimized stateful cookie parser. Cookies fields are added with the
 * {@link #addCookieField(String)} method and parsed on the next subsequent call to
 * {@link #getCookies()}. If the added fields are identical to those last added (as strings), then
 * the cookies are not re parsed.
 */
public class CookieCutter {

    private static final Logger LOG = Logger.getLogger(CookieCutter.class.getName());

    private final CookieCompliance _compliance;

    private Cookie[] _cookies;

    private Cookie[] _lastCookies;

    private final List<String> _fieldList = new ArrayList<>();

    int _fields;

    public CookieCutter() {
        this(CookieCompliance.RFC6265);
    }

    public CookieCutter(final CookieCompliance compliance) {
        _compliance = compliance;
    }

    public Cookie[] getCookies() {
        if (_cookies != null) return _cookies;

        if (_lastCookies != null && _fields == _fieldList.size()) _cookies = _lastCookies;
        else parseFields();
        _lastCookies = _cookies;
        return _cookies;
    }

    public void setCookies(final Cookie[] cookies) {
        _cookies = cookies;
        _lastCookies = null;
        _fieldList.clear();
        _fields = 0;
    }

    public void reset() {
        _cookies = null;
        _fields = 0;
    }

    public void addCookieField(String f) {
        if (f == null) return;
        f = f.trim();
        if (f.length() == 0) return;

        if (_fieldList.size() > _fields) {
            if (f.equals(_fieldList.get(_fields))) {
                _fields++;
                return;
            }

            while (_fieldList.size() > _fields)
                _fieldList.remove(_fields);
        }
        _cookies = null;
        _lastCookies = null;
        _fieldList.add(_fields++, f);
    }

    protected void parseFields() {
        _lastCookies = null;
        _cookies = null;

        final List<Cookie> cookies = new ArrayList<>();

        int version = 0;

        // delete excess fields
        while (_fieldList.size() > _fields)
            _fieldList.remove(_fields);

        StringBuilder unquoted = null;

        // For each cookie field
        for (final String hdr : _fieldList) {
            // Parse the header
            String name = null;

            Cookie cookie = null;

            boolean invalue = false;
            boolean inQuoted = false;
            boolean quoted = false;
            boolean escaped = false;
            int tokenstart = -1;
            int tokenend = -1;
            for (int i = 0, length = hdr.length(); i <= length; i++) {
                final char c = i == length ? 0 : hdr.charAt(i);

                // System.err.printf("i=%d/%d c=%s v=%b q=%b/%b e=%b u=%s s=%d e=%d \t%s=%s%n"
                // ,i,length,c==0?"|":(""+c),invalue,inQuoted,quoted,escaped,unquoted,tokenstart,tokenend,name,value);

                // Handle quoted values for name or value
                if (inQuoted) {
                    if (escaped) {
                        escaped = false;
                        if (c > 0) unquoted.append(c);
                        else {
                            unquoted.setLength(0);
                            inQuoted = false;
                            i--;
                        }
                        continue;
                    }

                    switch (c) {
                        case '"':
                            inQuoted = false;
                            quoted = true;
                            tokenstart = i;
                            tokenend = -1;
                            break;

                        case '\\':
                            escaped = true;
                            continue;

                        case 0:
                            // unterminated quote, let's ignore quotes
                            unquoted.setLength(0);
                            inQuoted = false;
                            i--;
                            continue;

                        default:
                            unquoted.append(c);
                            continue;
                    }
                } else {
                    // Handle name and value state machines
                    if (invalue) {
                        // parse the value
                        switch (c) {
                            case ' ':
                            case '\t':
                                break;

                            case ',':
                                if (_compliance != CookieCompliance.RFC2965) {
                                    if (quoted) {
                                        // must have been a bad internal quote. let's fix as best we
                                        // can
                                        unquoted.append(hdr, tokenstart, i--);
                                        inQuoted = true;
                                        quoted = false;
                                        continue;
                                    }
                                    if (tokenstart < 0) tokenstart = i;
                                    tokenend = i;
                                    continue;
                                }
                                // fall through
                            case 0:
                            case ';': {
                                String value;

                                if (quoted) {
                                    value = unquoted.toString();
                                    unquoted.setLength(0);
                                    quoted = false;
                                } else if (tokenstart >= 0)
                                    value =
                                        tokenend >= tokenstart
                                            ? hdr.substring(tokenstart, tokenend + 1)
                                            : hdr.substring(tokenstart);
                                else
                                    value = "";

                                try {
                                    if (name.startsWith("$")) {
                                        if (_compliance == CookieCompliance.RFC2965) {
                                            final String lowercaseName =
                                                name.toLowerCase(Locale.ENGLISH);
                                            switch (lowercaseName) {
                                                case "$path":
                                                    if (cookie != null) cookie.setPath(value);
                                                    break;
                                                case "$domain":
                                                    if (cookie != null) cookie.setDomain(value);
                                                    break;
                                                case "$port":
                                                    if (cookie != null)
                                                        cookie.setComment("$port=" + value);
                                                    break;
                                                case "$version":
                                                    version = Integer.parseInt(value);
                                                    break;
                                                default:
                                                    break;
                                            }
                                        }
                                    } else {
                                        cookie = new Cookie(name, value);
                                        if (version > 0) cookie.setVersion(version);
                                        cookies.add(cookie);
                                    }
                                } catch (final Exception e) {
                                    LOG.log(Level.FINE, "", e);
                                }

                                name = null;
                                tokenstart = -1;
                                invalue = false;

                                break;
                            }

                            case '"':
                                if (tokenstart < 0) {
                                    tokenstart = i;
                                    inQuoted = true;
                                    if (unquoted == null) unquoted = new StringBuilder();
                                    break;
                                }
                                // fall through to default case

                            default:
                                if (quoted) {
                                    // must have been a bad internal quote. let's fix as best we can
                                    unquoted.append(hdr, tokenstart, i--);
                                    inQuoted = true;
                                    quoted = false;
                                    continue;
                                }
                                if (tokenstart < 0) tokenstart = i;
                                tokenend = i;
                                continue;
                        }
                    } else {
                        // parse the name
                        switch (c) {
                            case ' ':
                            case '\t':
                                continue;

                            case '=':
                                if (quoted) {
                                    name = unquoted.toString();
                                    unquoted.setLength(0);
                                    quoted = false;
                                } else if (tokenstart >= 0)
                                    name =
                                        tokenend >= tokenstart
                                            ? hdr.substring(tokenstart, tokenend + 1)
                                            : hdr.substring(tokenstart);

                                tokenstart = -1;
                                invalue = true;
                                break;

                            default:
                                if (quoted) {
                                    // must have been a bad internal quote. let's fix as best we can
                                    unquoted.append(hdr, tokenstart, i--);
                                    inQuoted = true;
                                    quoted = false;
                                    continue;
                                }
                                if (tokenstart < 0) tokenstart = i;
                                tokenend = i;
                                continue;
                        }
                    }
                }
            }
        }

        _cookies = cookies.toArray(new Cookie[cookies.size()]);
        _lastCookies = _cookies;
    }

}
