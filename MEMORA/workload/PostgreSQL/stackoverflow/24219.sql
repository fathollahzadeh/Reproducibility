
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN vote.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT ph.PostId), 0) AS PostCount,
        MIN(u.CreationDate) OVER (PARTITION BY u.Id) AS FirstActivity
    FROM Users u
    LEFT JOIN Votes vote ON u.Id = vote.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
), 
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - p.CreationDate)) / 3600 AS AgeInHours,
        COUNT(c.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
), 
TrendingPosts AS (
    SELECT 
        ap.PostId,
        ap.Title,
        ap.ViewCount,
        (ap.CommentCount * 0.5 + GREATEST(ap.ViewCount / NULLIF(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - ap.CreationDate)) / 3600, 0), 1) * 0.5) AS EngagementScore
    FROM ActivePosts ap
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    tp.Title,
    tp.ViewCount,
    tp.EngagementScore,
    CASE 
        WHEN us.FirstActivity IS NOT NULL AND us.FirstActivity < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' THEN 'Veteran'
        WHEN us.Reputation < 100 THEN 'Newbie'
        ELSE 'Experienced'
    END AS UserTier
FROM UserStatistics us
LEFT JOIN TrendingPosts tp ON us.PostCount > 5
WHERE us.Reputation > 100 AND tp.EngagementScore > 1
ORDER BY tp.EngagementScore DESC, us.Reputation DESC
LIMIT 10;
