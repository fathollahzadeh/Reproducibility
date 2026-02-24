WITH PostAggregated AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id
)
SELECT 
    pa.PostId,
    pa.CommentCount,
    pa.UpVoteCount,
    pa.DownVoteCount,
    pa.AvgUserReputation,
    pt.Name AS PostType,
    p.Title,
    p.CreationDate
FROM 
    PostAggregated pa
JOIN 
    Posts p ON pa.PostId = p.Id
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
ORDER BY 
    pa.UpVoteCount DESC, pa.CommentCount DESC;