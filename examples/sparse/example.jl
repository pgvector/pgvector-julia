using HTTP, JSON, LibPQ, SparseArrays, Tables

conn = LibPQ.Connection("dbname=pgvector_example host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS documents")
execute(conn, "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding sparsevec(30522))")

module Pgvector
    using SparseArrays

    function convert(vec::AbstractSparseVector{Tv,Ti}) where {Tv<:Real,Ti<:Integer}
        elements = [string(i, ":", v) for (i, v) in zip(vec.nzind, vec.nzval)]
        string("{", join(elements, ","), "}/", vec.n)
    end
end

function embed(inputs)
    url = "http://localhost:3000/embed_sparse"
    data = Dict(
        "inputs" => inputs
    )
    headers = [
        "content-type" => "application/json"
    ]
    r = HTTP.request("POST", url, headers, JSON.json(data))
    [sparsevec(map(e -> e["index"] + 1, v), map(e -> e["value"], v), 30522) for v in JSON.parse(String(r.body))]
end

input = [
    "The dog is barking",
    "The cat is purring",
    "The bear is growling"
]
embeddings = embed(input)
LibPQ.load!(
    (content = input, embedding = map(Pgvector.convert, embeddings)),
    conn,
    "INSERT INTO documents (content, embedding) VALUES (\$1, \$2)",
)

query = "forest"
embedding = embed([query])[1]
result = execute(conn, "SELECT content FROM documents ORDER BY embedding <#> \$1 LIMIT 5", [Pgvector.convert(embedding)])
rows = Tables.rows(columntable(result))
for row in rows
    println(Tables.getcolumn(row, 1))
end

close(conn)
