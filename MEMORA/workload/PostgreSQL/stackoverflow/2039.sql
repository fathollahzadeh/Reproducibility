WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS TotalBadges,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
UserPosts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
),
RankedUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        UB.TotalBadges,
        UP.TotalPosts,
        UP.TotalQuestions,
        UP.TotalAnswers,
        UP.AvgScore,
        ROW_NUMBER() OVER (ORDER BY UB.TotalBadges DESC, UP.TotalPosts DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN 
        UserPosts UP ON U.Id = UP.OwnerUserId
)
SELECT 
    R.UserRank,
    R.DisplayName,
    COALESCE(R.TotalBadges, 0) AS TotalBadges,
    COALESCE(R.TotalPosts, 0) AS TotalPosts,
    COALESCE(R.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(R.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(R.AvgScore, 0) AS AvgScore,
    CASE 
        WHEN R.AvgScore IS NULL THEN 'No Posts'
        WHEN R.AvgScore > 10 THEN 'High Scorer'
        WHEN R.AvgScore BETWEEN 1 AND 10 THEN 'Average Scorer'
        ELSE 'Low Scorer'
    END AS ScoreCategory
FROM 
    RankedUsers R
WHERE 
    R.TotalPosts > 5
ORDER BY 
    R.UserRank
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
