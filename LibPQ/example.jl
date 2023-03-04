using LibPQ, Tables

conn = LibPQ.Connection("dbname=pgvector_julia_test host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS items")
execute(conn, "CREATE TABLE items (embedding vector(3))")

module Pgvector
    convert(v::AbstractVector{T}) where T<:Real = string("[", join(v, ","), "]")

    parse(v::String) = map(x -> Base.parse(Float32, x), split(v[2:end-1], ","))
end

embeddings = [1 1 1; 2 2 2; 1 1 2]
LibPQ.load!(
    (embedding = map(Pgvector.convert, eachrow(embeddings)),),
    conn,
    "INSERT INTO items (embedding) VALUES (\$1)",
)

embedding = Pgvector.convert([1, 1, 1])
result = execute(conn, "SELECT * FROM items ORDER BY embedding <-> \$1 LIMIT 5", [embedding])
data = columntable(result)
println(map(Pgvector.parse, data.embedding))

execute(conn, "CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)")

close(conn)
