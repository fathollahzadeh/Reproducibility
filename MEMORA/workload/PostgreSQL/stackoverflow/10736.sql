WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        pt.Name AS PostType,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(b.Id) AS BadgeCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY p.Id, pt.Name
)

SELECT 
    ps.PostId,
    ps.PostType,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.BadgeCount,
    ps.AvgUserReputation
FROM PostStats ps
ORDER BY ps.PostId;