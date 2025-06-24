using LibPQ

struct HalfVector
    vec::Base.Vector{Float16}
end

function Base.parse(::Type{HalfVector}, pqv::LibPQ.PQBinaryValue{OID}) where {OID}
    ptr = LibPQ.data_pointer(pqv)

    dim = ntoh(unsafe_load(Ptr{Int16}(ptr)))
    ptr += sizeof(Int16)

    # TODO check unused
    unused = ntoh(unsafe_load(Ptr{Int16}(ptr)))
    ptr += sizeof(Int16)

    vec = []
    for i = 1:dim
        v = ntoh(unsafe_load(Ptr{Float16}(ptr)))
        ptr += sizeof(Float16)
        append!(vec, v)
    end

    HalfVector(vec)
end

function Base.parse(::Type{HalfVector}, pqv::LibPQ.PQTextValue{OID}) where {OID}
    s = unsafe_string(pqv)
    HalfVector(map(x -> Base.parse(Float16, x), split(s[2:end-1], ",")))
end

function Base.show(io::IO, vec::HalfVector)
    print(io, string("[", join(vec.vec, ","), "]"))
end
