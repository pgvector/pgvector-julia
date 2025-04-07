using LibPQ, Tables

conn = LibPQ.Connection("dbname=pgvector_julia_test host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS items")
execute(conn, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")

module Pgvector
    convert(vec::AbstractVector{T}) where T<:Number = string("[", join(vec, ","), "]")

    parse(str::String) = map(x -> Base.parse(Float32, x), split(str[2:end-1], ","))
end

embeddings = [[1, 1, 1], [2, 2, 2], [1, 1, 2]]
LibPQ.load!(
    (embedding = map(Pgvector.convert, embeddings),),
    conn,
    "INSERT INTO items (embedding) VALUES (\$1)",
)

embedding = Pgvector.convert([1, 1, 1])
result = execute(conn, "SELECT * FROM items ORDER BY embedding <-> \$1 LIMIT 5", [embedding])
data = columntable(result)
println(map(Pgvector.parse, data.embedding))

execute(conn, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")

close(conn)
