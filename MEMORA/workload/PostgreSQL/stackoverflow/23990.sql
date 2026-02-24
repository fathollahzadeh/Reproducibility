
WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
), UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
), PostHistoryCounts AS (
    SELECT
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        STRING_AGG(PHT.Name, ', ') AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id 
    WHERE 
        PH.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    U.DisplayName,
    U.Reputation,
    UR.TotalPosts,
    UR.PositivePosts,
    UR.NegativePosts,
    PHC.EditCount,
    PHC.EditTypes,
    COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 2), 0) AS UpVotes,
    COALESCE((SELECT COUNT(*) FROM Votes V WHERE V.PostId = RP.PostId AND V.VoteTypeId = 3), 0) AS DownVotes,
    CASE 
        WHEN RP.ViewCount > 1000 THEN 'Highly Viewed'
        WHEN RP.ViewCount > 500 THEN 'Moderately Viewed'
        ELSE 'Less Viewed'
    END AS ViewCategory,
    CASE 
        WHEN U.Reputation > 1000 THEN 'High Reputation'
        WHEN U.Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM 
    RecentPosts RP
JOIN 
    Users U ON RP.OwnerUserId = U.Id
LEFT JOIN 
    UserReputation UR ON U.Id = UR.UserId
LEFT JOIN 
    PostHistoryCounts PHC ON RP.PostId = PHC.PostId
WHERE 
    RP.UserPostRank = 1
ORDER BY 
    RP.CreationDate DESC
FETCH FIRST 100 ROWS ONLY;
