
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        COUNT(DISTINCT P.Id) AS TotalPosts, 
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
BadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(*) AS TotalBadges 
    FROM 
        Badges 
    GROUP BY 
        UserId
),
PostHistoryStats AS (
    SELECT 
        PH.UserId, 
        COUNT(*) AS TotalPostHistoryEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TotalTitleEdits,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosures
    FROM 
        PostHistory PH
    GROUP BY 
        PH.UserId
)
SELECT 
    U.DisplayName, 
    US.Reputation,
    US.TotalPosts,
    US.TotalQuestions,
    US.TotalAnswers,
    US.TotalUpvotes,
    US.TotalDownvotes,
    COALESCE(BC.TotalBadges, 0) AS TotalBadges,
    COALESCE(PHS.TotalPostHistoryEdits, 0) AS TotalPostHistoryEdits,
    COALESCE(PHS.TotalTitleEdits, 0) AS TotalTitleEdits,
    COALESCE(PHS.TotalClosures, 0) AS TotalClosures
FROM 
    Users U
JOIN 
    UserStats US ON U.Id = US.UserId
LEFT JOIN 
    BadgeCounts BC ON U.Id = BC.UserId
LEFT JOIN 
    PostHistoryStats PHS ON U.Id = PHS.UserId
WHERE 
    U.Reputation > 1000
ORDER BY 
    U.Reputation DESC, 
    US.TotalPosts DESC
LIMIT 50;
