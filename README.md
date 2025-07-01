# Pgvector.jl

[pgvector](https://github.com/pgvector/pgvector) support for Julia

Supports [LibPQ.jl](https://github.com/iamed2/LibPQ.jl)

[![Build Status](https://github.com/pgvector/Pgvector.jl/actions/workflows/build.yml/badge.svg)](https://github.com/pgvector/Pgvector.jl/actions)

## Getting Started

Follow the instructions for your database library:

- [LibPQ.jl](#libpqjl)

Or check out some examples:

- [Embeddings](examples/openai/example.jl) with OpenAI
- [Binary embeddings](examples/cohere/example.jl) with Cohere
- [Hybrid search](examples/hybrid/example.jl) with Ollama (Reciprocal Rank Fusion)
- [Sparse search](examples/sparse/example.jl) with Text Embeddings Inference
- [Morgan fingerprints](examples/morgan/example.jl) with RDKitMinimalLib.jl
- [Bulk loading](examples/loading/example.jl) with `COPY`

## LibPQ.jl

Add the package

```text
pkg> add Pgvector
```

Load the package

```julia
using Pgvector
```

Enable the extension

```julia
execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
```

Register the types with your connection

```julia
Pgvector.register!(conn)
```

Create a table

```julia
execute(conn, "CREATE TABLE items (id bigserial PRIMARY KEY, embedding vector(3))")
```

Insert vectors

```julia
embeddings = [[1, 1, 1], [2, 2, 2], [1, 1, 2]]
LibPQ.load!(
    (embedding = map(Pgvector.Vector, embeddings),),
    conn,
    "INSERT INTO items (embedding) VALUES (\$1)",
)
```

Get the nearest neighbors

```julia
embedding = Pgvector.Vector([1, 1, 1])
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

## Reference

### Vectors

Create a vector

```julia
vec = Pgvector.Vector([1, 2, 3])
```

Get a `Vector{Float32}`

```julia
vec.vec
```

### Half Vectors

Create a half vector

```julia
vec = Pgvector.HalfVector([1, 2, 3])
```

Get a `Vector{Float16}`

```julia
vec.vec
```

### Sparse Vectors

Create a sparse vector

```julia
vec = Pgvector.SparseVector(sparsevec([1, 0, 2, 0, 3, 0]))
```

Get a `SparseVector{Float32,Int32}`

```julia
vec.vec
```

## History

View the [changelog](https://github.com/pgvector/Pgvector.jl/blob/master/CHANGELOG.md)

## Contributing

Everyone is encouraged to help improve this project. Here are a few ways you can help:

- [Report bugs](https://github.com/pgvector/Pgvector.jl/issues)
- Fix bugs and [submit pull requests](https://github.com/pgvector/Pgvector.jl/pulls)
- Write, clarify, or fix documentation
- Suggest or add new features

To get started with development:

```sh
git clone https://github.com/pgvector/Pgvector.jl.git
cd Pgvector.jl
createdb pgvector_julia_test
julia --project=. -e "using Pkg; Pkg.instantiate()"
julia --project=. -e "using Pkg; Pkg.test()"
```

To run an example:

```sh
cd examples/loading
createdb pgvector_example
julia --project=. -e "using Pkg; Pkg.instantiate()"
julia --project=. example.jl
```
