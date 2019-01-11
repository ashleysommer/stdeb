# -*- coding: utf-8 -*-
#
"""
A replacement transport for Python xmlrpc library.

Usage:

    >>> import xmlrpclib
    >>> from transport import RequestsTransport
    >>> s = xmlrpclib.ServerProxy('http://yoursite.com/xmlrpc', transport=RequestsTransport())
    >>> s.demo.sayHello()
    Hello!
"""
from xmlrpc.client import Transport, ProtocolError
import requests
import requests.utils
from distutils.version import StrictVersion
import warnings

class RequestsTransport(Transport):
    """
    Drop in Transport for xmlrpclib that uses Requests instead of httplib
    """
    # change our user agent to reflect Requests
    user_agent = "Python XMLRPC with Requests (python-requests.org)"

    # override this if you'd like to https
    use_https = False

    def request(self, host, handler, request_body, verbose=False):
        """
        Make an xmlrpc request.
        """
        headers = {'User-Agent': self.user_agent,
                   'Content-Type': 'text/xml',
                   }
        url = self._build_url(host, handler)
        kwargs = {}
        if StrictVersion(requests.__version__) >= StrictVersion('0.8.8'):
            kwargs['verify']=True
        else:
            if self.use_https:
                warnings.warn('using https transport but no certificate '
                              'verification. (Hint: upgrade requests package.)')
        try:
            resp = requests.post(url, data=request_body, headers=headers,
                                 **kwargs)
        except ValueError:
            raise
        except Exception:
            raise # something went wrong
        else:
            try:
                resp.raise_for_status()
            except requests.RequestException as e:
                raise ProtocolError(url, resp.status_code,
                                    str(e), resp.headers)
            else:
                return self.parse_response(resp)

    def parse_response(self, resp):
        """
        Parse the xmlrpc response.
        """
        p, u = self.getparser()

        if hasattr(resp,'text'):
            # modern requests will do this for us
            text = resp.text  # this is a str
        else:
            encoding = requests.utils.get_encoding_from_headers(resp.headers)
            if encoding is None:
                encoding='utf-8' # FIXME: what to do here?
            text = resp.content.decode(encoding, errors='replace')
        p.feed(text)
        p.close()
        return u.close()

    def _build_url(self, host, handler):
        """
        Build a url for our request based on the host, handler and use_http
        property
        """
        scheme = 'https' if self.use_https else 'http'
        return '%s://%s/%s' % (scheme, host, handler)
