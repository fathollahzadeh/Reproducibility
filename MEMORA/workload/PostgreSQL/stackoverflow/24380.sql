
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        p.ViewCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount 
        FROM Comments 
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT 
            ParentId, 
            COUNT(*) AS AnswerCount 
        FROM Posts 
        WHERE PostTypeId = 2 
        GROUP BY ParentId
    ) a ON p.Id = a.ParentId
),
UserPostStats AS (
    SELECT 
        ub.UserId,
        COUNT(DISTINCT up.Id) AS TotalPosts,
        SUM(pm.Score) AS TotalScore,
        SUM(pm.ViewCount) AS TotalViews,
        SUM(pm.CommentCount) AS TotalComments,
        SUM(pm.AnswerCount) AS TotalAnswers,
        MAX(pm.PostRank) AS HighestPostRank,
        AVG(pm.Score) AS AvgPostScore
    FROM UserBadges ub
    JOIN Posts up ON ub.UserId = up.OwnerUserId
    LEFT JOIN PostMetrics pm ON up.Id = pm.PostId
    GROUP BY ub.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ubs.BadgeCount, 0) AS BadgeCount,
    COALESCE(ubs.BadgeNames, 'No Badges') AS BadgeNames,
    ups.TotalPosts,
    ups.TotalScore,
    ups.TotalViews,
    ups.TotalComments,
    ups.TotalAnswers,
    ups.HighestPostRank,
    ups.AvgPostScore
FROM Users u
LEFT JOIN UserBadges ubs ON u.Id = ubs.UserId
LEFT JOIN UserPostStats ups ON u.Id = ups.UserId
WHERE 
    u.Reputation > 1000  
    AND (ups.TotalPosts IS NOT NULL OR ubs.BadgeCount > 0)  
ORDER BY 
    ups.TotalScore DESC,
    ups.TotalPosts DESC,
    u.DisplayName ASC;
