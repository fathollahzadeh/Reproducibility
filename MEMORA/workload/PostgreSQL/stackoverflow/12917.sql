WITH PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(v.Id) AS VoteCount,
        AVG(u.Reputation) AS AverageUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON v.UserId = u.Id
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    pvs.PostId,
    pvs.Title,
    pvs.CreationDate,
    pvs.Score,
    pvs.ViewCount,
    pvs.VoteCount,
    pvs.AverageUserReputation,
    COALESCE(c.CommentCount, 0) AS CommentCount
FROM 
    PostVoteSummary pvs
LEFT JOIN 
    (SELECT 
         PostId, COUNT(*) AS CommentCount
     FROM 
         Comments
     GROUP BY 
         PostId) c ON pvs.PostId = c.PostId
ORDER BY 
    pvs.Score DESC, 
    pvs.ViewCount DESC 
LIMIT 100;