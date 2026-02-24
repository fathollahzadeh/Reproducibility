WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews,
        AVG(p.AnswerCount) AS AvgAnswers,
        AVG(p.CommentCount) AS AvgComments
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.OwnerUserId
),
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ubc.BadgeCount, 0) AS BadgeCount,
        ps.PostCount,
        ps.TotalScore,
        ps.TotalViews,
        ps.AvgAnswers,
        ps.AvgComments,
        RANK() OVER (ORDER BY u.Reputation DESC, ps.TotalScore DESC) AS ReputationRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadgeCounts ubc ON u.Id = ubc.UserId
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
)
SELECT 
    ru.Id,
    ru.DisplayName,
    ru.Reputation,
    ru.BadgeCount,
    ru.PostCount,
    ru.TotalScore,
    ru.TotalViews,
    ru.AvgAnswers,
    ru.AvgComments,
    ru.ReputationRank
FROM 
    RankedUsers ru
WHERE 
    ru.ReputationRank <= 10
ORDER BY 
    ru.ReputationRank;