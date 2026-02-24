
WITH RECURSIVE UserPostCounts AS (
    SELECT
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
),
UserReputationBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(DISTINCT b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
CloseReasons AS (
    SELECT
        ph.PostId,
        STRING_AGG(cr.Name, ', ') AS CloseReasonNames
    FROM PostHistory ph
    INNER JOIN CloseReasonTypes cr ON CAST(ph.Comment AS INT) = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY ph.PostId
),
PostScores AS (
    SELECT
        p.Id,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        AVG(v.BountyAmount) OVER (PARTITION BY p.OwnerUserId) AS AvgBounty
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  
)
SELECT
    u.DisplayName,
    u.Reputation,
    COALESCE(up.PostCount, 0) AS TotalPosts,
    COALESCE(up.QuestionCount, 0) AS TotalQuestions,
    COALESCE(up.AnswerCount, 0) AS TotalAnswers,
    COALESCE(ub.BadgeCount, 0) AS TotalBadges,
    COALESCE(ub.BadgeNames, 'None') AS BadgeNames,
    p.Title AS TopPostTitle,
    p.Score AS TopPostScore,
    ps.Rank AS TopPostRank,
    ps.AvgBounty AS AvgBountyAwarded,
    cr.CloseReasonNames
FROM Users u
LEFT JOIN UserPostCounts up ON u.Id = up.UserId
LEFT JOIN UserReputationBadges ub ON u.Id = ub.UserId
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostScores ps ON p.Id = ps.Id
LEFT JOIN CloseReasons cr ON p.Id = cr.PostId
WHERE u.Reputation > 1000  
AND ps.Rank = 1  
ORDER BY u.Reputation DESC, TotalPosts DESC;
