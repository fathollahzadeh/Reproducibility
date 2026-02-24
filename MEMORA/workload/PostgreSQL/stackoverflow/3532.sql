WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        RANK() OVER (PARTITION BY U.Id ORDER BY C.CreationDate DESC) AS RecentCommentRank,
        C.Text AS LastCommentText
    FROM 
        Users U
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
),
AggregatedData AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.Reputation,
        U.TotalPosts,
        U.TotalQuestions,
        U.TotalAnswers,
        U.TotalBounty,
        R.LastCommentText
    FROM 
        UserStatistics U
    LEFT JOIN 
        RecentActivity R ON U.UserId = R.UserId AND R.RecentCommentRank = 1
)
SELECT 
    A.DisplayName,
    A.TotalPosts,
    A.TotalQuestions,
    A.TotalAnswers,
    A.TotalBounty,
    COALESCE(A.LastCommentText, 'No comments made') AS LastCommentText,
    CASE 
        WHEN A.Reputation > 1000 THEN 'High Reputation'
        WHEN A.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    AggregatedData A
WHERE 
    A.TotalPosts > 10
ORDER BY 
    A.Reputation DESC
LIMIT 50;

