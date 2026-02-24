
WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
), UserPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(p.Score) AS AvgPostScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId IS NOT NULL
    GROUP BY 
        p.OwnerUserId
), UserWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), FinalStats AS (
    SELECT 
        R.UserId,
        R.DisplayName,
        R.Reputation,
        us.TotalPosts,
        us.TotalQuestions,
        us.TotalAnswers,
        us.AvgPostScore,
        us.TotalViews,
        ub.TotalBadges,
        R.ReputationRank
    FROM 
        RankedUsers R
    JOIN 
        UserPostStats us ON R.UserId = us.OwnerUserId
    JOIN 
        UserWithBadges ub ON R.UserId = ub.UserId
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    AvgPostScore,
    TotalViews,
    TotalBadges,
    ReputationRank
FROM 
    FinalStats
ORDER BY 
    ReputationRank, TotalPosts DESC
FETCH FIRST 100 ROWS ONLY;
