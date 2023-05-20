## 1.2.0

- Enable support of Dart 3.

## 1.1.0

- Add proper support for errors from the source `Stream`. Errors are forwarded to the output stream of `CsvData`.
- Treat as empty any cell that contains only whitespace characters as defined by [Unicode](https://en.wikipedia.org/wiki/Whitespace_character).

## 1.0.0

- Lightweight, cross-platform Dart package to read CSV data from a `Stream`. Supports and extends RFC 4180.
