
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
CloseReasonSummary AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CASE WHEN PHT.Name IS NOT NULL THEN PHT.Name END, ', ') AS CloseReasons,
        COUNT(DISTINCT PH.UserId) AS NumOfCloseVotes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PHT.Name LIKE '%Close%'
    GROUP BY 
        PH.PostId
),
HighReputationUsers AS (
    SELECT 
        UserId, 
        MAX(Reputation) AS MaxReputation
    FROM 
        UserStatistics
    WHERE 
        ReputationRank < 100
    GROUP BY 
        UserId
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    U.DisplayName,
    U.TotalUpvotes,
    U.TotalDownvotes,
    U.TotalBadges,
    PWC.Title,
    PWC.CommentCount,
    CR.CloseReasons,
    CR.NumOfCloseVotes
FROM 
    UserStatistics U
JOIN 
    HighReputationUsers HRU ON U.UserId = HRU.UserId
LEFT JOIN 
    PostsWithComments PWC ON U.UserId = PWC.PostId
LEFT JOIN 
    CloseReasonSummary CR ON PWC.PostId = CR.PostId
WHERE 
    U.TotalUpvotes - U.TotalDownvotes > 50
    AND U.Reputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    U.TotalUpvotes DESC, U.DisplayName
OFFSET 10 ROWS
FETCH NEXT 5 ROWS ONLY;
