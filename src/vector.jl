struct Vector
    vec::Base.Vector{Float32}
end

function Base.parse(::Type{Vector}, s::String)
    Vector(map(x -> Base.parse(Float32, x), split(s[2:end-1], ",")))
end

function Base.show(io::IO, vec::Vector)
    print(io, string("[", join(vec.vec, ","), "]"))
end
