using HTTP, JSON, LibPQ, Tables

conn = LibPQ.Connection("dbname=pgvector_example host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS documents")
execute(conn, "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(1536))")

module Pgvector
    convert(v::AbstractVector{T}) where T<:Real = string("[", join(v, ","), "]")
end

function embed(input)
    url = "https://api.openai.com/v1/embeddings"
    data = Dict(
        "input" => input,
        "model" => "text-embedding-3-small"
    )
    headers = [
        "authorization" => string("Bearer ", ENV["OPENAI_API_KEY"]),
        "content-type" => "application/json"
    ]
    r = HTTP.request("POST", url, headers, JSON.json(data))
    [map(identity, v["embedding"]) for v in JSON.parse(String(r.body))["data"]]
end

input = [
    "The dog is barking",
    "The cat is purring",
    "The bear is growling"
]
embeddings = embed(input)
LibPQ.load!(
    (content = input, embedding = map(Pgvector.convert, embeddings),),
    conn,
    "INSERT INTO documents (content, embedding) VALUES (\$1, \$2)",
)

query = "forest"
embedding = embed([query])[1]
result = execute(conn, "SELECT id FROM documents ORDER BY embedding <=> \$1 LIMIT 5", [Pgvector.convert(embedding)])
rows = Tables.rows(columntable(result))
for row in rows
    println(Tables.getcolumn(row, 1))
end

close(conn)
