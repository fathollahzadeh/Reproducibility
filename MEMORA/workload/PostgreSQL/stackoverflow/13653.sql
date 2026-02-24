
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.PostCount,
    us.CommentCount,
    us.UpVotes,
    us.DownVotes,
    us.Reputation
FROM 
    Users u
JOIN 
    UserStatistics us ON u.Id = us.UserId
ORDER BY 
    us.Reputation DESC, 
    us.PostCount DESC
LIMIT 100;
