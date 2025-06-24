using LibPQ, SparseArrays

struct SparseVector
    vec::SparseArrays.SparseVector{Float32,Int32}
end

function Base.parse(::Type{SparseVector}, pqv::LibPQ.PQBinaryValue{OID}) where {OID}
    ptr = LibPQ.data_pointer(pqv)

    dim = ntoh(unsafe_load(Ptr{Int32}(ptr)))
    ptr += sizeof(Int32)

    nnz = ntoh(unsafe_load(Ptr{Int32}(ptr)))
    ptr += sizeof(Int32)

    unused = ntoh(unsafe_load(Ptr{Int32}(ptr)))
    ptr += sizeof(Int32)
    if unused != 0
        error("expected unused to be 0")
    end

    indices = []
    for i = 1:nnz
        v = ntoh(unsafe_load(Ptr{Int32}(ptr)))
        ptr += sizeof(Int32)
        append!(indices, v + 1)
    end

    values = []
    for i = 1:nnz
        v = ntoh(unsafe_load(Ptr{Float32}(ptr)))
        ptr += sizeof(Float32)
        append!(values, v)
    end

    SparseVector(sparsevec(indices, values, dim))
end

function Base.parse(::Type{SparseVector}, pqv::LibPQ.PQTextValue{OID}) where {OID}
    s = unsafe_string(pqv)
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
