# Rmd rendering

    Code
      cat(result)
    Output
      ## Basic query
      
          SELECT 1 as val;
      
          ## ┌───────┐
          ## │  val  │
          ## │ int32 │
          ## ├───────┤
          ## │     1 │
          ## └───────┘
      
      ## Create and query
      
          CREATE TABLE students (id INT, name TEXT, grade DOUBLE);
      
          INSERT INTO students VALUES (1, 'Alice', 95.5), (2, 'Bob', 87.3), (3, 'Carol', 92.1);
      
          SELECT * FROM students ORDER BY grade DESC;
      
          ## ┌───────┬─────────┬────────┐
          ## │  id   │  name   │ grade  │
          ## │ int32 │ varchar │ double │
          ## ├───────┼─────────┼────────┤
          ## │     1 │ Alice   │   95.5 │
          ## │     3 │ Carol   │   92.1 │
          ## │     2 │ Bob     │   87.3 │
          ## └───────┴─────────┴────────┘
      
      ## Mode chunk option
      
          SELECT * FROM students ORDER BY id;
      
          ## id,name,grade
          ## 1,Alice,95.5
          ## 2,Bob,87.3
          ## 3,Carol,92.1
      
      ## Inline mode change persists
      
          .mode markdown
      
          SELECT name, grade FROM students WHERE grade > 90;
      
          ## | name  | grade |
          ## |-------|------:|
          ## | Alice | 95.5  |
          ## | Carol | 92.1  |
      
          SELECT name FROM students WHERE grade < 90;
      
          ## | name |
          ## |------|
          ## | Bob  |
      
      ## Eval false
      
          SELECT 'not evaluated';
      
      ## Error display
      
          SELCT bad syntax;
      
          ## Parser Error: syntax error at or near "SELCT"
          ## 
          ## LINE 1: SELCT bad syntax;
          ##         ^

# qmd rendering

    Code
      cat(result)
    Output
      # duckknit qmd test
      
      
      ## Basic query
      
      ``` duckdb
      SELECT 1 as val;
      ```
      
          ┌───────┐
          │  val  │
          │ int32 │
          ├───────┤
          │     1 │
          └───────┘
      
      ## Create and query
      
      ``` duckdb
      CREATE TABLE students (id INT, name TEXT, grade DOUBLE);
      INSERT INTO students VALUES (1, 'Alice', 95.5), (2, 'Bob', 87.3), (3, 'Carol', 92.1);
      ```
      
      ``` duckdb
      SELECT * FROM students ORDER BY grade DESC;
      ```
      
          ┌───────┬─────────┬────────┐
          │  id   │  name   │ grade  │
          │ int32 │ varchar │ double │
          ├───────┼─────────┼────────┤
          │     1 │ Alice   │   95.5 │
          │     3 │ Carol   │   92.1 │
          │     2 │ Bob     │   87.3 │
          └───────┴─────────┴────────┘
      
      ## Mode chunk option
      
      ``` duckdb
      SELECT * FROM students ORDER BY id;
      ```
      
          id,name,grade
          1,Alice,95.5
          2,Bob,87.3
          3,Carol,92.1
      
      ## Inline mode change persists
      
      ``` duckdb
      .mode markdown
      SELECT name, grade FROM students WHERE grade > 90;
      ```
      
          | name  | grade |
          |-------|------:|
          | Alice | 95.5  |
          | Carol | 92.1  |
      
      ``` duckdb
      SELECT name FROM students WHERE grade < 90;
      ```
      
          | name |
          |------|
          | Bob  |
      
      ## Eval false
      
      ``` duckdb
      SELECT 'not evaluated';
      ```
      
      ## Error display
      
      ``` duckdb
      SELCT bad syntax;
      ```
      
          Parser Error: syntax error at or near "SELCT"
      
          LINE 1: SELCT bad syntax;
                  ^

