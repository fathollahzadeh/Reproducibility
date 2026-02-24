WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        u.UpVotes,
        u.DownVotes,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COUNT(DISTINCT p.Id) AS PostsCount,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views, u.UpVotes, u.DownVotes, b.Name
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.Views,
    up.PostsCount,
    up.TotalScore,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount
FROM UserStatistics up
JOIN RecentPosts rp ON up.UserId = rp.OwnerUserId
WHERE up.Reputation > 1000
  AND rp.CommentCount > 5
  AND EXISTS (
      SELECT 1 FROM Votes v 
      WHERE v.PostId = rp.PostId 
        AND v.VoteTypeId = 2  
        AND v.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 week'
  )
ORDER BY up.Reputation DESC, rp.Score DESC
LIMIT 50;