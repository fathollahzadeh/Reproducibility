WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        AVG(v.BountyAmount) AS AverageBounty,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.PostTypeId, p.OwnerUserId
)

SELECT 
    PostStats.PostId,
    PostStats.PostTypeId,
    Users.DisplayName AS OwnerDisplayName,
    PostStats.CommentCount,
    PostStats.VoteCount,
    PostStats.UpVotes,
    PostStats.DownVotes,
    PostStats.AverageBounty
FROM 
    PostStats
JOIN 
    Users ON PostStats.OwnerUserId = Users.Id
ORDER BY 
    PostStats.VoteCount DESC;