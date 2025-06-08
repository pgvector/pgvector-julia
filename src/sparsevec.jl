using SparseArrays

struct SparseVector
    vec::SparseArrays.SparseVector{Float32,Int32}
end

function Base.parse(::Type{SparseVector}, s::String)
    elements, dim = rsplit(s, "/"; limit=2)
    elements = map(e -> split(e, ":"; limit=2), split(elements[2:end-1], ","))
    indices = map(v -> Base.parse(Int32, v[1]), elements)
    values = map(v -> Base.parse(Float32, v[2]), elements)
    SparseVector(sparsevec(indices, values, Base.parse(Int32, dim)))
end

function Base.show(io::IO, vec::SparseVector)
    elements = [string(i, ":", v) for (i, v) in zip(vec.vec.nzind, vec.vec.nzval)]
    print(io, string("{", join(elements, ","), "}/", vec.vec.n))
end
