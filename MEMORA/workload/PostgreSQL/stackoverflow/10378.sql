WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= '2023-01-01' 
    GROUP BY 
        p.Id, p.Title, p.PostTypeId
)
SELECT 
    pst.PostId,
    pst.Title,
    pst.PostTypeId,
    pst.CommentCount,
    pst.VoteCount,
    pst.BadgeCount,
    pst.UpVoteCount,
    pst.DownVoteCount,
    u.Reputation,
    u.CreationDate AS UserCreationDate
FROM 
    PostStatistics pst
JOIN 
    Users u ON pst.PostId = u.Id
ORDER BY 
    pst.VoteCount DESC, pst.CommentCount DESC;