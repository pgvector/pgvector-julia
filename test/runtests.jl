using LibPQ, Pgvector, SparseArrays, Tables, Test

conn = LibPQ.Connection("dbname=pgvector_julia_test host=localhost")
execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
Pgvector.register!(conn)

@testset "Vector" begin
    vec = Pgvector.Vector([1, 2, 3])
    @test string(vec) == "[1.0,2.0,3.0]"

    vec = columntable(execute(conn, "SELECT '[1,2,3]'::vector"))[1][1]
    @test vec.vec == [1, 2, 3]

    vec = columntable(execute(conn, "SELECT '[1,2,3]'::vector", binary_format=true))[1][1]
    @test vec.vec == [1, 2, 3]
end

@testset "HalfVector" begin
    vec = Pgvector.HalfVector([1, 2, 3])
    @test string(vec) == "[1.0,2.0,3.0]"

    vec = columntable(execute(conn, "SELECT '[1,2,3]'::halfvec"))[1][1]
    @test vec.vec == [1, 2, 3]

    vec = columntable(execute(conn, "SELECT '[1,2,3]'::halfvec", binary_format=true))[1][1]
    @test vec.vec == [1, 2, 3]
end

@testset "SparseVector" begin
    vec = Pgvector.SparseVector(sparsevec([1, 0, 2, 0, 3, 0]))
    @test string(vec) == "{1:1.0,3:2.0,5:3.0}/6"

    vec = columntable(execute(conn, "SELECT '{1:1,3:2,5:3}/6'::sparsevec"))[1][1]
    @test vec.vec == sparsevec([1, 0, 2, 0, 3, 0])

    vec = columntable(execute(conn, "SELECT '{1:1,3:2,5:3}/6'::sparsevec", binary_format=true))[1][1]
    @test vec.vec == sparsevec([1, 0, 2, 0, 3, 0])
end
