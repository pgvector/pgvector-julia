using HTTP, JSON, LibPQ, Tables

conn = LibPQ.Connection("dbname=pgvector_example host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS documents")
execute(conn, "CREATE TABLE documents (id bigserial PRIMARY KEY, content text, embedding vector(768))")
execute(conn, "CREATE INDEX ON documents USING GIN (to_tsvector('english', content))")

module Pgvector
    convert(v::AbstractVector{T}) where T<:Real = string("[", join(v, ","), "]")
end

function embed(input, task)
    # nomic-embed-text uses a task prefix
    # https://huggingface.co/nomic-ai/nomic-embed-text-v1.5
    input = [string(task, ": ", v) for v in input]

    url = "http://localhost:11434/api/embed"
    data = Dict(
        "input" => input,
        "model" => "nomic-embed-text"
    )
    headers = [
        "content-type" => "application/json"
    ]
    r = HTTP.request("POST", url, headers, JSON.json(data))
    [map(identity, v) for v in JSON.parse(String(r.body))["embeddings"]]
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

sql = "
WITH semantic_search AS (
    SELECT id, RANK () OVER (ORDER BY embedding <=> \$2) AS rank
    FROM documents
    ORDER BY embedding <=> \$2
    LIMIT 20
),
keyword_search AS (
    SELECT id, RANK () OVER (ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC)
    FROM documents, plainto_tsquery('english', \$1) query
    WHERE to_tsvector('english', content) @@ query
    ORDER BY ts_rank_cd(to_tsvector('english', content), query) DESC
    LIMIT 20
)
SELECT
    COALESCE(semantic_search.id, keyword_search.id) AS id,
    COALESCE(1.0 / (\$3 + semantic_search.rank), 0.0) +
    COALESCE(1.0 / (\$3 + keyword_search.rank), 0.0) AS score
FROM semantic_search
FULL OUTER JOIN keyword_search ON semantic_search.id = keyword_search.id
ORDER BY score DESC
LIMIT 5
"
query = "growling bear"
embedding = embed([query], "search_query")[1]
k = 60
result = execute(conn, sql, [query, Pgvector.convert(embedding), k])
rows = Tables.rows(columntable(result))
for row in rows
    id = Tables.getcolumn(row, 1)
    score = Tables.getcolumn(row, 2)
    println("document: ", id, ", RRF score: ", score)
end

close(conn)
