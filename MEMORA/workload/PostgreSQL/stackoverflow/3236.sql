
WITH UserPerformance AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS TotalQuestions,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBountyEarned,
        AVG(CASE WHEN V.VoteTypeId = 2 THEN V.BountyAmount END) AS AvgUpvotes,
        AVG(CASE WHEN V.VoteTypeId = 3 THEN V.BountyAmount END) AS AvgDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ClosedPosts AS (
    SELECT 
        PH.UserId,
        COUNT(PH.PostId) AS ClosedCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.UserId
),
TopUsers AS (
    SELECT 
        UP.UserId,
        UP.DisplayName,
        UP.Reputation,
        UP.TotalPosts,
        UP.TotalQuestions,
        UP.TotalAnswers,
        COALESCE(CP.ClosedCount, 0) AS ClosedCount,
        ROW_NUMBER() OVER (ORDER BY UP.Reputation DESC) AS Rank
    FROM 
        UserPerformance UP
    LEFT JOIN 
        ClosedPosts CP ON UP.UserId = CP.UserId
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalQuestions,
    TU.TotalAnswers,
    TU.ClosedCount,
    TU.Reputation,
    CASE 
        WHEN TU.Reputation >= 10000 THEN 'Gold'
        WHEN TU.Reputation >= 5000 THEN 'Silver'
        WHEN TU.Reputation >= 1000 THEN 'Bronze'
        ELSE 'New User' 
    END AS BadgeRank
FROM 
    TopUsers TU
WHERE 
    TU.Rank <= 10
ORDER BY 
    TU.Reputation DESC;
