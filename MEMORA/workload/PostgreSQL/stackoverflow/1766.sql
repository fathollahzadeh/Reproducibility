WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.ViewCount) AS TotalViews,
        AVG(COALESCE(P.Score, 0)) AS AvgScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
TopBadgers AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
RankedUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.TotalViews,
        UA.AvgScore,
        TB.BadgeCount,
        RANK() OVER (ORDER BY UA.TotalViews DESC) AS RankByViews,
        RANK() OVER (ORDER BY UA.AvgScore DESC) AS RankByScore
    FROM 
        UserActivity UA
    LEFT JOIN 
        TopBadgers TB ON UA.UserId = TB.UserId
)
SELECT 
    R.DisplayName,
    R.TotalPosts,
    R.TotalQuestions,
    R.TotalAnswers,
    R.TotalViews,
    R.AvgScore,
    COALESCE(R.BadgeCount, 0) AS BadgeCount,
    R.RankByViews,
    R.RankByScore
FROM 
    RankedUsers R
WHERE 
    R.TotalPosts > 10
    AND (R.RankByViews <= 10 OR R.RankByScore <= 10)
ORDER BY 
    R.RankByViews, R.RankByScore;
