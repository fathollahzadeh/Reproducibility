WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1  
      AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(v.BountyAmount) AS TotalBounty,
        AVG(p.Score) AS AvgScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
),
CommentSummary AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM Comments c
    GROUP BY c.PostId
)
SELECT 
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    u.UserId,
    u.TotalPosts,
    u.TotalBounty,
    u.AvgScore,
    COALESCE(cs.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN COALESCE(cs.CommentCount, 0) > 10 THEN 'Popular'
        WHEN COALESCE(cs.CommentCount, 0) BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionLevel,
    CASE 
        WHEN u.TotalPosts IS NULL THEN 'No Posts'
        ELSE 'Has Posts'
    END AS UserPostStatus
FROM RankedPosts r
INNER JOIN UserStats u ON r.OwnerUserId = u.UserId
LEFT JOIN CommentSummary cs ON r.PostId = cs.PostId
WHERE r.RecentPostRank = 1
  AND r.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1)  
  AND r.ViewCount IS NOT NULL
ORDER BY r.Score DESC, r.ViewCount DESC
LIMIT 50
OFFSET 0;