WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostDetails AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        P.ViewCount,
        P.OwnerUserId,
        COALESCE(UP.DisplayName, 'Community User') AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostsCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN Users UP ON P.OwnerUserId = UP.Id
    WHERE P.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId, UP.DisplayName
), 
PopularPosts AS (
    SELECT 
        PD.PostId, 
        PD.Title, 
        PD.CreationDate, 
        PD.Score, 
        PD.ViewCount, 
        PD.OwnerDisplayName,
        RANK() OVER (ORDER BY PD.ViewCount DESC) AS ViewRank
    FROM PostDetails PD
    WHERE PD.Score > 0
)
SELECT 
    UR.ReputationRank,
    UR.DisplayName,
    PP.Title AS PopularPostTitle,
    PP.ViewCount AS PopularPostViewCount,
    PP.OwnerDisplayName AS PostOwner,
    PHT.Name AS PostHistoryType
FROM UserReputation UR
JOIN Posts P ON UR.UserId = P.OwnerUserId
JOIN PostHistory PH ON P.Id = PH.PostId
JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
JOIN PopularPosts PP ON P.Id = PP.PostId
WHERE UR.Reputation > 1000 AND PHT.Name IS NOT NULL
ORDER BY UR.ReputationRank, PP.ViewCount DESC
LIMIT 50;