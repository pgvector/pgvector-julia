using HTTP, JSON, LibPQ, Tables

conn = LibPQ.Connection("dbname=pgvector_example host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS documents")
execute(conn, "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1024))")

module Pgvector
    convert(v::AbstractVector{T}) where T<:Real = string("[", join(v, ","), "]")
end

function embed(texts, type)
    url = "https://api.cohere.com/v1/embed"
    data = Dict(
        "texts" => texts,
        "model" => "embed-english-v3.0",
        "input_type" => type,
        "embedding_types" => ["float"]
    )
    headers = [
        "authorization" => string("Bearer ", ENV["CO_API_KEY"]),
        "content-type" => "application/json"
    ]
    r = HTTP.request("POST", url, headers, JSON.json(data))
    [map(identity, v) for v in JSON.parse(String(r.body))["embeddings"]["float"]]
end

input = [
    "The dog is barking",
    "The cat is purring",
    "The bear is growling"
]
embeddings = embed(input, "search_document")
LibPQ.load!(
    (content = input, embedding = map(Pgvector.convert, embeddings),),
    conn,
    "INSERT INTO documents (content, embedding) VALUES (\$1, \$2)",
)

query = "forest"
embedding = embed([query], "search_query")[1]
result = execute(conn, "SELECT id FROM documents ORDER BY embedding <=> \$1 LIMIT 5", [Pgvector.convert(embedding)])
rows = Tables.rows(columntable(result))
for row in rows
    println(Tables.getcolumn(row, 1))
end

close(conn)
