class Todo {
  final String who;
  final String what;

  const Todo(this.who, this.what);
}

@Todo("AppRouter", "implement app router")
void appRouter() {
  print("Implement app router");
}
