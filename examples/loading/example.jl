using LibPQ, Pgvector

# generate random data
rows = 100000
dimensions = 128
embeddings = rand(Float32, (rows, dimensions))

# enable extension
conn = LibPQ.Connection("dbname=pgvector_example host=localhost")
execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")

# create table
execute(conn, "DROP TABLE IF EXISTS items")
execute(conn, "CREATE TABLE items (id bigserial, embedding vector(128))")

# load data
println("Loading ", rows, " rows")
data = map(v -> "$(Pgvector.Vector(v))\n", eachrow(embeddings))
copyin = LibPQ.CopyIn("COPY items (embedding) FROM STDIN", data)
execute(conn, copyin)
println("Success!")

# create any indexes *after* loading initial data (skipping for this example)
create_index = false
if create_index
    println("Creating index")
    execute(conn, "SET maintenance_work_mem = '8GB'")
    execute(conn, "SET max_parallel_maintenance_workers = 7")
    execute(conn, "CREATE INDEX ON items USING hnsw (embedding vector_cosine_ops)")
end

# update planner statistics for good measure
execute(conn, "ANALYZE items")

close(conn)
