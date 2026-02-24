WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN P.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseReopenActions,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),

PostHistoryStats AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        COUNT(*) AS HistoryActions,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPost,
        MAX(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedPost,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    INNER JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PH.UserId
),

TopUsers AS (
    SELECT 
        UserId,
        RANK() OVER (ORDER BY SUM(Reputation) DESC) AS UserRank
    FROM 
        UserStats
    WHERE 
        TotalPosts > 5
    GROUP BY 
        UserId
)

SELECT 
    U.DisplayName,
    U.Reputation,
    PS.TotalPosts,
    PS.Questions,
    PS.Answers,
    PH.HistoryActions,
    PH.HistoryTypes,
    COALESCE(NULLIF((SELECT COUNT(DISTINCT V.Id) 
                     FROM Votes V 
                     WHERE V.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)), 0), (SELECT COUNT(DISTINCT C.Id) 
                     FROM Comments C 
                     WHERE C.UserId = U.Id)) AS VoteToCommentRatio,
    CASE 
        WHEN PS.ReputationRank <= 3 THEN 'Top User'
        WHEN PS.ReputationRank BETWEEN 4 AND 10 THEN 'Good User'
        ELSE 'Regular User'
    END AS UserCategory
FROM 
    Users U
JOIN 
    UserStats PS ON PS.UserId = U.Id
LEFT JOIN 
    PostHistoryStats PH ON PH.UserId = U.Id
JOIN 
    TopUsers TU ON TU.UserId = U.Id
WHERE 
    U.Location IS NOT NULL 
    AND U.Location <> ''
    AND PS.Reputation > 100 
    AND (PS.TotalPosts > 0 OR PH.HistoryActions > 0)
ORDER BY 
    U.Reputation DESC, PS.TotalPosts DESC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;