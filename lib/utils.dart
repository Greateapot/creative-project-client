final RegExp _isURL = RegExp(
  r'https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)',
  dotAll: true,
);

bool isURL(String url) => _isURL.hasMatch(url);
