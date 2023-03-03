using LibPQ, Tables

conn = LibPQ.Connection("dbname=pgvector_julia_test")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS items")
execute(conn, "CREATE TABLE items (embedding vector(3))")

LibPQ.load!(
    (embedding = ["[1,1,1]", "[2,2,2]", "[1,1,2]"],),
    conn,
    "INSERT INTO items (embedding) VALUES (\$1)",
)

result = execute(conn, "SELECT * FROM items ORDER BY embedding <-> \$1 LIMIT 5", ["[1,1,1]"])
data = columntable(result)
println(data)

execute(conn, "CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)")

close(conn)
