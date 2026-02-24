WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        AVG(P.Score) AS AvgScore,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.OwnerUserId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.PostCount,
    U.VoteCount,
    U.BadgeCount,
    PS.CommentCount,
    PS.AvgScore,
    PS.CloseCount
FROM 
    UserStats U
JOIN 
    PostStats PS ON U.UserId = PS.OwnerUserId
ORDER BY 
    U.Reputation DESC, U.PostCount DESC;