using LibPQ

struct Vector
    vec::Base.Vector{Float32}
end

function Base.parse(::Type{Vector}, pqv::LibPQ.PQBinaryValue{OID}) where {OID}
    ptr = LibPQ.data_pointer(pqv)

    dim = ntoh(unsafe_load(Ptr{Int16}(ptr)))
    ptr += sizeof(Int16)

    unused = ntoh(unsafe_load(Ptr{Int16}(ptr)))
    ptr += sizeof(Int16)
    if unused != 0
        error("expected unused to be 0")
    end

    vec = []
    for i = 1:dim
        v = ntoh(unsafe_load(Ptr{Float32}(ptr)))
        ptr += sizeof(Float32)
        append!(vec, v)
    end

    Vector(vec)
end

function Base.parse(::Type{Vector}, pqv::LibPQ.PQTextValue{OID}) where {OID}
    s = unsafe_string(pqv)
    Vector(map(x -> Base.parse(Float32, x), split(s[2:end-1], ",")))
end

function Base.show(io::IO, vec::Vector)
    print(io, string("[", join(vec.vec, ","), "]"))
end
