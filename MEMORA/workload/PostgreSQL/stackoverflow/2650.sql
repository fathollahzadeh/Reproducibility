WITH UserBadgeCount AS (
    SELECT UserId, COUNT(*) AS TotalBadges
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(pc.Count, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        pb.TotalBadges
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS Count
        FROM Comments
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS AnswerCount
        FROM Posts
        WHERE PostTypeId = 2
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN UserBadgeCount pb ON p.OwnerUserId = pb.UserId
    WHERE p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
RankedPosts AS (
    SELECT 
        ps.*,
        ROW_NUMBER() OVER (PARTITION BY TotalBadges ORDER BY Score DESC) AS BadgeRank
    FROM PostStats ps
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    rp.AnswerCount,
    rp.TotalBadges,
    CASE 
        WHEN rp.BadgeRank <= 5 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM RankedPosts rp
WHERE rp.Score > (
    SELECT AVG(Score)
    FROM Posts
    WHERE CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
)
ORDER BY PostCategory, rp.Score DESC
LIMIT 100;