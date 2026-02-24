WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN P.Score ELSE 0 END) AS PositiveScore,
        SUM(CASE WHEN P.Score < 0 THEN P.Score ELSE 0 END) AS NegativeScore,
        AVG(P.ViewCount) AS AvgViewCount,
        DENSE_RANK() OVER (ORDER BY COUNT(DISTINCT P.Id) DESC) AS UserRank
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 500 AND 
        U.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        PostCount, 
        PositiveScore, 
        NegativeScore, 
        AvgViewCount,
        UserRank
    FROM 
        UserActivity 
    WHERE 
        UserRank <= 10
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C) AS CommentCount,
        COUNT(V) AS VoteCount,
        MAX(PH.CreationDate) AS LastPostHistory
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        P.Id, P.OwnerUserId
)
SELECT 
    TU.DisplayName, 
    TU.Reputation, 
    TU.PostCount, 
    TU.PositiveScore, 
    TU.NegativeScore, 
    TU.AvgViewCount,
    PS.LastPostHistory,
    PS.CommentCount,
    PS.VoteCount
FROM 
    TopUsers TU
LEFT JOIN 
    PostStats PS ON TU.UserId = PS.OwnerUserId
WHERE 
    PS.CommentCount > 5 OR PS.VoteCount > 10
ORDER BY 
    TU.Reputation DESC, 
    TU.PostCount DESC
LIMIT 20;