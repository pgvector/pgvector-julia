# pgvector-julia

[pgvector](https://github.com/pgvector/pgvector) examples for Julia

Supports [LibPQ.jl](https://github.com/iamed2/LibPQ.jl)

[![Build Status](https://github.com/pgvector/pgvector-julia/workflows/build/badge.svg?branch=master)](https://github.com/pgvector/pgvector-julia/actions)

## Getting Started

Follow the instructions for your database library:

- [LibPQ.jl](#libpq-jl)

## LibPQ.jl

Create a table

```julia
execute(conn, "CREATE TABLE items (embedding vector(3))")
```

Insert vectors

```julia
LibPQ.load!(
    (embedding = ["[1,1,1]", "[2,2,2]", "[1,1,2]"],),
    conn,
    "INSERT INTO items (embedding) VALUES (\$1)",
)
```

Get the nearest neighbors

```julia
result = execute(conn, "SELECT * FROM items ORDER BY embedding <-> \$1 LIMIT 5", ["[1,1,1]"])
columntable(result)
```

Add an approximate index

```julia
execute(conn, "CREATE INDEX my_index ON items USING ivfflat (embedding vector_l2_ops)")
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
julia --project=. LibPQ/example.jl
```
