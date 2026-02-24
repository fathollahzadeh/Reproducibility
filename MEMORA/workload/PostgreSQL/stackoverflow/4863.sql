WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.CreationDate,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        CRT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON PH.Comment::int = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
), 
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.ViewCount,
    RP.RankScore,
    RP.CommentCount,
    COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
    US.UserId,
    US.Reputation,
    US.PostCount,
    US.TotalScore,
    US.AvgViews
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
JOIN 
    UserStats US ON RP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = US.UserId)
WHERE 
    RP.RankScore <= 5 
ORDER BY 
    RP.RankScore, US.Reputation DESC
LIMIT 100;