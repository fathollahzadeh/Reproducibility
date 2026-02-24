WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        SUM(V.BountyAmount) AS TotalBountyPoints
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id
),
PostFrequency AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        AVG(P.ViewCount) AS AvgViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(US.TotalPosts, 0) AS TotalPosts,
    COALESCE(US.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(US.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(US.TotalBadges, 0) AS TotalBadges,
    COALESCE(US.TotalBountyPoints, 0) AS TotalBountyPoints,
    COALESCE(PF.PostCount, 0) AS PostCount,
    COALESCE(PF.AvgViews, 0) AS AvgViews,
    COALESCE(PF.AvgScore, 0) AS AvgScore
FROM 
    Users U
LEFT JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    PostFrequency PF ON U.Id = PF.OwnerUserId
ORDER BY 
    U.Reputation DESC;