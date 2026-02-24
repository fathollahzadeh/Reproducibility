
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(TAGS.TagName) AS TagCount,
        SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END) AS CommentCount,
        SUM(V.BountyAmount) AS TotalBounty,
        P.Title,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    LEFT JOIN (SELECT unnest(string_to_array(P.Tags, '>')) AS TagName, P.Id FROM Posts P) AS TAGS ON TAGS.Id = P.Id
    GROUP BY P.Id, P.OwnerUserId, P.Title
), 
PostHistoryDetails AS (
    SELECT
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(DISTINCT PH.UserId) AS EditorsCount,
        STRING_AGG(DISTINCT PH.UserDisplayName, ', ') AS Editors
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6, 10, 11)  
    GROUP BY PH.PostId
)
SELECT 
    U.UserId,
    U.Reputation,
    U.ReputationRank,
    PS.PostId,
    PS.Title,
    PS.TagCount,
    PS.CommentCount,
    PS.TotalBounty,
    PH.LastEditDate,
    PH.EditorsCount,
    PH.Editors
FROM UserReputation U
JOIN PostStatistics PS ON U.UserId = PS.OwnerUserId
LEFT JOIN PostHistoryDetails PH ON PS.PostId = PH.PostId
WHERE 
    U.Reputation > (SELECT AVG(Reputation) FROM Users) 
    AND PS.TagCount > 3 
    AND PS.RecentPostRank = 1
ORDER BY U.Reputation DESC, PS.CommentCount DESC
LIMIT 50;
