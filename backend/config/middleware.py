class SimpleEmailAuthMiddleware:
    """
    Middleware to extract X-User-Email header and set it to request.user_email
    for simple MVP authentication.
    """
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Extract email from headers
        # Use HTTP_X_USER_EMAIL or look up from request.headers
        email = request.headers.get('X-User-Email', None)
        if not email:
            email = "guest@example.com"
            
        request.user_email = email
        
        response = self.get_response(request)
        return response
