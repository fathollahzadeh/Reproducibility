
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(p.Score) AS AvgPostScore,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE((SELECT COUNT(c.Id) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(a.Id) FROM Posts a WHERE a.ParentId = p.Id), 0) AS AnswerCount
    FROM 
        Posts p
)
SELECT 
    us.DisplayName,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    us.AvgPostScore,
    us.PostCount,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.AnswerCount
FROM 
    UserStats us
JOIN 
    Posts p ON us.UserId = p.OwnerUserId
JOIN 
    PostStats ps ON p.Id = ps.PostId
ORDER BY 
    us.PostCount DESC, us.UpVotes DESC;
