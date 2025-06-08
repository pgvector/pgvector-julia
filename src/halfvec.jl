struct HalfVector
    vec::Base.Vector{Float16}
end

function Base.parse(::Type{HalfVector}, s::String)
    HalfVector(map(x -> Base.parse(Float16, x), split(s[2:end-1], ",")))
end

function Base.show(io::IO, vec::HalfVector)
    print(io, string("[", join(vec.vec, ","), "]"))
end
