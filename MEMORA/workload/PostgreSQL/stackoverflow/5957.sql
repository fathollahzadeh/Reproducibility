WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS TotalDownvotedPosts,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUserPosts AS (
    SELECT 
        PU.UserId,
        U.DisplayName,
        P.Title,
        P.Score,
        P.CreationDate,
        RANK() OVER (PARTITION BY PU.UserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        UserStatistics U ON U.UserId = P.OwnerUserId
    JOIN 
        (SELECT UserId FROM UserStatistics WHERE TotalPosts > 0) PU ON U.UserId = PU.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalQuestions,
    U.TotalAnswers,
    U.TotalUpvotedPosts,
    U.TotalDownvotedPosts,
    U.TotalBadges,
    T.Title AS TopPostTitle,
    T.Score AS TopPostScore,
    T.CreationDate AS TopPostDate
FROM 
    UserStatistics U
LEFT JOIN 
    TopUserPosts T ON U.UserId = T.UserId AND T.PostRank = 1
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.TotalPosts DESC, U.Reputation DESC
LIMIT 10;
