using LibPQ, Tables

function register!(conn::LibPQ.Connection)
    result = execute(conn, "SELECT to_regtype('vector')::oid AS vector_oid, to_regtype('halfvec')::oid AS halfvec_oid, to_regtype('sparsevec')::oid AS sparsevec_oid")
    data = columntable(result)

    vector_oid = data.vector_oid[1]
    if ismissing(vector_oid)
        error("vector type not found in the database")
    end
    conn.type_map[vector_oid] = Vector

    halfvec_oid = data.halfvec_oid[1]
    if !ismissing(halfvec_oid)
        conn.type_map[halfvec_oid] = HalfVector
    end

    sparsevec_oid = data.sparsevec_oid[1]
    if !ismissing(sparsevec_oid)
        conn.type_map[sparsevec_oid] = SparseVector
    end

    nothing
end
