
WITH UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount 
    FROM Badges 
    WHERE Date > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY UserId
),
RecentPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount, 
           COALESCE(COUNT(c.Id), 0) AS CommentCount,
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount, 
           COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount 
    FROM Posts p 
    LEFT JOIN Comments c ON p.Id = c.PostId 
    LEFT JOIN Votes v ON p.Id = v.PostId 
    WHERE p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' 
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.ViewCount
    ORDER BY p.ViewCount DESC
    LIMIT 10
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, ub.BadgeCount, 
           RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank 
    FROM Users u 
    JOIN UserBadges ub ON u.Id = ub.UserId 
    WHERE u.Reputation > 1000
),
PostSummaries AS (
    SELECT rp.Title, rp.ViewCount, rp.CommentCount, 
           tu.DisplayName AS TopUserName, 
           tu.Reputation, 
           tu.BadgeCount 
    FROM RecentPosts rp 
    JOIN TopUsers tu ON rp.OwnerUserId = tu.Id
)
SELECT 
    ps.Title, ps.ViewCount, ps.CommentCount, 
    ps.TopUserName, ps.Reputation, ps.BadgeCount,
    CASE 
        WHEN ps.CommentCount > 5 THEN 'Highly Discussed' 
        WHEN ps.ViewCount > 1000 THEN 'Popular' 
        ELSE 'Standard' 
    END AS PostCategory
FROM PostSummaries ps
WHERE ps.Reputation > 500
ORDER BY ps.ViewCount DESC, ps.CommentCount DESC;
