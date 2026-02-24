WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.ViewCount, p.Score
    HAVING COUNT(c.Id) > 5 OR COUNT(DISTINCT v.Id) > 10
),
TopUsers AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        ub.BadgeCount,
        ROW_NUMBER() OVER (ORDER BY ub.BadgeCount DESC) AS Rank
    FROM UserBadges ub
    WHERE ub.BadgeCount > 0
),
EngagementMetrics AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.BadgeCount,
    pp.Title,
    pp.ViewCount,
    pp.Score,
    emp.UpVotes,
    emp.DownVotes
FROM TopUsers t
JOIN PopularPosts pp ON pp.PostId IN (
    SELECT DISTINCT PostId 
    FROM EngagementMetrics em 
    WHERE em.UpVotes - em.DownVotes > 10
)
JOIN EngagementMetrics emp ON pp.PostId = emp.PostId
WHERE t.Rank <= 10
ORDER BY t.BadgeCount DESC, pp.ViewCount DESC;