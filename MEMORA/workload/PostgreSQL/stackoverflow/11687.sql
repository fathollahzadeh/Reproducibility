WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        u.Reputation AS OwnerReputation,
        COUNT(CASE WHEN c.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN v.Id IS NOT NULL THEN 1 END) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, u.Reputation
)

SELECT 
    pst.PostId,
    pst.PostTypeId,
    pst.OwnerReputation,
    pst.CommentCount,
    pst.VoteCount,
    pst.UpVoteCount,
    pst.DownVoteCount,
    pt.Name AS PostTypeName
FROM 
    PostStats pst
JOIN 
    PostTypes pt ON pst.PostTypeId = pt.Id
ORDER BY 
    pst.VoteCount DESC, 
    pst.CommentCount DESC
LIMIT 100;