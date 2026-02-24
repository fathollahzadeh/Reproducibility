
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
ServerStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        COUNT(CASE WHEN PH.PostId IS NOT NULL THEN 1 END) AS TotalHistoryEntries,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.OwnerUserId
)
SELECT 
    COALESCE(US.UserId, SS.OwnerUserId) AS UserId,
    COALESCE(US.DisplayName, '') AS DisplayName,
    COALESCE(US.Reputation, 0) AS Reputation,
    COALESCE(US.TotalBounties, 0) AS TotalBounties,
    COALESCE(US.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(US.TotalDownvotes, 0) AS TotalDownvotes,
    COALESCE(SS.TotalPosts, 0) AS TotalPosts,
    COALESCE(SS.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(SS.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(SS.TotalHistoryEntries, 0) AS TotalHistoryEntries,
    COALESCE(SS.AvgPostScore, 0) AS AvgPostScore
FROM 
    UserStats US
FULL OUTER JOIN 
    ServerStats SS ON US.UserId = SS.OwnerUserId
WHERE 
    (COALESCE(US.TotalUpvotes, 0) + COALESCE(US.TotalDownvotes, 0)) > 10 OR 
    (COALESCE(SS.TotalPosts, 0) > 5 AND COALESCE(SS.AvgPostScore, 0) > 10)
ORDER BY 
    COALESCE(US.Reputation, 0) DESC,
    COALESCE(SS.TotalPosts, 0) DESC
LIMIT 20;
