WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UniqueVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(LENGTH(p.Body)) AS AvgPostLength,
        MAX(p.CreationDate) AS LastActivityDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate BETWEEN '2022-01-01' AND '2023-12-31'
    GROUP BY p.Id, p.PostTypeId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    ps.PostId,
    ps.PostTypeId,
    ps.CommentCount,
    ps.UniqueVoteCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.AvgPostLength,
    us.UserId,
    us.BadgeCount,
    us.AvgReputation,
    us.TotalViews
FROM PostStats ps
JOIN UserStats us ON ps.PostId = us.UserId
ORDER BY ps.PostId
LIMIT 100;