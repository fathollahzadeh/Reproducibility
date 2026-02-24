
WITH UserRankings AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Score, 
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        RANK() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS PopularityRank,
        P.OwnerUserId
    FROM 
        Posts P 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, P.OwnerUserId
),
UserPostCounts AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        P.OwnerUserId
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= DATE '2024-10-01' - INTERVAL '30 days'
    GROUP BY 
        V.PostId
)
SELECT 
    UR.DisplayName,
    UR.Reputation,
    U.PostCount,
    PP.Title,
    PP.Score,
    PP.CommentCount,
    RV.TotalVotes,
    PP.PopularityRank
FROM 
    UserRankings UR
JOIN 
    UserPostCounts U ON UR.UserId = U.OwnerUserId
JOIN 
    PopularPosts PP ON U.OwnerUserId = PP.OwnerUserId
JOIN 
    RecentVotes RV ON PP.PostId = RV.PostId
WHERE 
    UR.ReputationRank <= 100
ORDER BY 
    PP.PopularityRank, 
    UR.Reputation DESC;
