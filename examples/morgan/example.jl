using MolecularGraph, LibPQ, Tables

conn = LibPQ.Connection("dbname=pgvector_example host=localhost")

execute(conn, "CREATE EXTENSION IF NOT EXISTS vector")
execute(conn, "DROP TABLE IF EXISTS molecules")
execute(conn, "CREATE TABLE molecules (id text PRIMARY KEY, fingerprint bit(2048))")

function generate_fingerprint(molecule)
    join(map(b -> b ? "1" : "0", morgan_fp_vector(smilestomol(molecule))))
end

molecules = ["Cc1ccccc1", "Cc1ncccc1", "c1ccccn1"]
fingerprints = map(mol -> generate_fingerprint(mol), molecules)
LibPQ.load!(
    (id = molecules, fingerprint = fingerprints),
    conn,
    "INSERT INTO molecules (id, fingerprint) VALUES (\$1, \$2)",
)

query = "c1ccco1"
fingerprint = generate_fingerprint(query)
result = execute(conn, "SELECT id, fingerprint <%> \$1 AS distance FROM molecules ORDER BY distance LIMIT 5", [fingerprint])
rows = Tables.rows(columntable(result))
for row in rows
    id = Tables.getcolumn(row, 1)
    distance = Tables.getcolumn(row, 2)
    println(id, ": ", distance)
end

close(conn)
