WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
), UserActivity AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    up.DisplayName,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    ub.TotalBadges,
    ub.BadgeNames,
    ua.TotalAnswers,
    ua.AcceptedAnswers
FROM RankedPosts rp
JOIN Users up ON rp.PostId = up.Id
LEFT JOIN UserBadges ub ON up.Id = ub.UserId
LEFT JOIN UserActivity ua ON up.Id = ua.UserId
WHERE rp.RankByScore = 1 
  AND rp.ViewCount > 1000 
  AND (ub.TotalBadges > 0 OR ua.AcceptedAnswers > 0) 
ORDER BY rp.CreationDate DESC;