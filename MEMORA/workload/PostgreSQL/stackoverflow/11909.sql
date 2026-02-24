WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.Reputation
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(p.AnswerCount, 0)) AS TotalAnswers,
        SUM(COALESCE(p.CommentCount, 0)) AS TotalComments
    FROM Posts p
    GROUP BY p.OwnerUserId
),
FinalStats AS (
    SELECT
        us.UserId,
        us.Reputation,
        us.BadgeCount,
        us.TotalViews,
        us.TotalScore,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(ps.TotalComments, 0) AS TotalComments
    FROM UserStats us
    LEFT JOIN PostStats ps ON us.UserId = ps.OwnerUserId
)

SELECT 
    UserId,
    Reputation,
    BadgeCount,
    TotalViews,
    TotalScore,
    PostCount,
    TotalAnswers,
    TotalComments
FROM FinalStats
ORDER BY Reputation DESC;