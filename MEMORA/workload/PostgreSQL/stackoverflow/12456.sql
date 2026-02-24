
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
        COALESCE(d.DownVoteCount, 0) AS DownVoteCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS UpVoteCount
         FROM Votes
         WHERE VoteTypeId = 2 
         GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS DownVoteCount
         FROM Votes
         WHERE VoteTypeId = 3 
         GROUP BY PostId) d ON p.Id = d.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, v.UpVoteCount, d.DownVoteCount
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.CommentCount,
    ps.BadgeCount,
    (ps.UpVoteCount - ps.DownVoteCount) AS NetVoteScore
FROM 
    PostStats ps
ORDER BY 
    NetVoteScore DESC;
