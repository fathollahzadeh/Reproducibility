
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalViews,
        LastPostDate,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM 
        UserPostStats
),
ClosedPostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(ph.Id) AS TotalClosures,
        COUNT(DISTINCT p.Id) AS UniqueClosedPosts
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.TotalScore,
    tu.TotalViews,
    tu.LastPostDate,
    COALESCE(cps.TotalClosures, 0) AS TotalClosures,
    COALESCE(cps.UniqueClosedPosts, 0) AS UniqueClosedPosts,
    CASE 
        WHEN tu.TotalAnswers = 0 THEN 0 
        ELSE (tu.TotalScore * 1.0 / NULLIF(tu.TotalAnswers, 0))
    END AS ScorePerAnswer
FROM 
    TopUsers tu
LEFT JOIN 
    ClosedPostStats cps ON tu.UserId = cps.OwnerUserId
WHERE 
    tu.ScoreRank <= 10 
ORDER BY 
    tu.TotalScore DESC, 
    tu.TotalPosts DESC;
