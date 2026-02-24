WITH UserActivity AS (
    SELECT
        u.Id AS UserId,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000  
    GROUP BY u.Id
),
FilteredUsers AS (
    SELECT
        UserId,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalBounty,
        BadgeCount,
        RANK() OVER (PARTITION BY BadgeCount ORDER BY TotalViews DESC) AS ViewRank,
        RANK() OVER (PARTITION BY BadgeCount ORDER BY TotalBounty DESC) AS BountyRank
    FROM UserActivity
),
UserPerformance AS (
    SELECT
        UserId,
        QuestionCount,
        AnswerCount,
        TotalViews,
        TotalBounty,
        BadgeCount,
        CASE 
            WHEN ViewRank = 1 THEN 'Top Viewer'
            ELSE 'Regular Viewer' 
        END AS ViewerStatus,
        CASE 
            WHEN BountyRank = 1 THEN 'Top Bounty Hunter'
            ELSE 'Regular Hunter'
        END AS BountyStatus
    FROM FilteredUsers
    WHERE BadgeCount > 0
)
SELECT 
    u.Id,
    u.DisplayName,
    up.QuestionCount,
    up.AnswerCount,
    up.TotalViews,
    up.TotalBounty,
    up.ViewerStatus,
    up.BountyStatus
FROM Users u
JOIN UserPerformance up ON u.Id = up.UserId
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        AVG(COALESCE(c.Score, 0)) AS AverageCommentScore, 
        COUNT(c.Id) AS TotalComments
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.OwnerUserId
) AS CommentStats ON u.Id = CommentStats.OwnerUserId
WHERE up.QuestionCount > 5 AND up.TotalViews > 1000
ORDER BY 
    up.TotalBounty DESC, 
    up.TotalViews DESC,
    up.QuestionCount DESC;