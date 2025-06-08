using LibPQ, Pgvector, Tables

conn = LibPQ.Connection("dbname=pgvector_julia_test host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS items")
execute(conn, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")

Pgvector.register!(conn)

embeddings = [[1, 1, 1], [2, 2, 2], [1, 1, 2]]
LibPQ.load!(
    (embedding = map(Pgvector.Vector, embeddings),),
    conn,
    "INSERT INTO items (embedding) VALUES (\$1)",
)

embedding = [1, 1, 1]
result = execute(conn, "SELECT * FROM items ORDER BY embedding <-> \$1 LIMIT 5", [Pgvector.Vector(embedding)])
data = columntable(result)
println(data)

execute(conn, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")

close(conn)
