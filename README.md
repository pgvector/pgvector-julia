# pgvector-julia

[pgvector](https://github.com/pgvector/pgvector) examples for Julia

Supports [LibPQ.jl](https://github.com/iamed2/LibPQ.jl)

[![Build Status](https://github.com/pgvector/pgvector-julia/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/pgvector-julia/actions)

## Getting Started

Follow the instructions for your database library:

- [LibPQ.jl](#libpqjl)

Or check out some examples:

- [Embeddings](examples/openai/example.jl) with OpenAI
- [Binary embeddings](examples/cohere/example.jl) with Cohere
- [Hybrid search](examples/hybrid/example.jl) with Ollama (Reciprocal Rank Fusion)
- [Sparse search](examples/sparse/example.jl) with Text Embeddings Inference

## LibPQ.jl

Enable the extension

```julia
execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
```

Create a table

```julia
execute(conn, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")
```

Insert vectors

```julia
module Pgvector
    convert(v::AbstractVector{T}) where T<:Real = string("[", join(v, ","), "]")
end

embeddings = [1 1 1; 2 2 2; 1 1 2]
LibPQ.load!(
    (embedding = map(Pgvector.convert, eachrow(embeddings)),),
    conn,
    "INSERT INTO items (embedding) VALUES (\$1)",
)
```

Get the nearest neighbors

```julia
embedding = Pgvector.convert([1, 1, 1])
result = execute(conn, "SELECT * FROM items ORDER BY embedding <-> \$1 LIMIT 5", [embedding])
columntable(result)
```

Add an approximate index

```julia
execute(conn, "CREATE INDEX ON items USING hnsw (embedding vector_l2_ops)")
# or
execute(conn, "CREATE INDEX ON items USING ivfflat (embedding vector_l2_ops) WITH (lists = 100)")
```

Use `vector_ip_ops` for inner product and `vector_cosine_ops` for cosine distance

See a [full example](LibPQ/example.jl)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/pgvector-julia/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/pgvector-julia/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/pgvector-julia.git
cd pgvector-julia
createdb pgvector_julia_test
julia --project=. -e "using Pkg; Pkg.instantiate()"
julia --project=. LibPQ/example.jl
```

To run an example:

```sh
cd examples/openai
createdb pgvector_example
julia --project=. -e "using Pkg; Pkg.instantiate()"
julia --project=. example.jl
```
