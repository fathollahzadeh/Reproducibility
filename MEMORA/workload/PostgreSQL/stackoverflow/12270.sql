WITH PostSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        pt.Name AS PostTypeName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        SUM(CASE WHEN vt.Id IS NOT NULL THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Id IS NOT NULL THEN 0 ELSE 1 END) AS DownVotes
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        p.Id, p.Title, p.PostTypeId, pt.Name
)
SELECT 
    ps.PostId, 
    ps.Title, 
    ps.PostTypeName, 
    ps.TotalComments, 
    ps.TotalVotes, 
    ps.UpVotes, 
    ps.DownVotes
FROM 
    PostSummary ps
ORDER BY 
    ps.TotalVotes DESC, ps.TotalComments DESC;