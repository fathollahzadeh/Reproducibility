
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.Reputation IS NULL THEN 'No Reputation'
            WHEN U.Reputation > 1000 THEN 'High Reputation'
            ELSE 'Low Reputation' 
        END AS ReputationCategory
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Tags,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAYS'
),
PostLinksData AS (
    SELECT 
        PL.PostId,
        PL.RelatedPostId,
        LT.Name AS LinkType,
        COUNT(*) OVER (PARTITION BY PL.PostId) AS RelatedPostCount
    FROM PostLinks PL
    JOIN LinkTypes LT ON PL.LinkTypeId = LT.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        C.Name AS CloseReason,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS CloseEntry
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.Comment::INT = C.Id
    WHERE PH.PostHistoryTypeId = 10
),
CombinedData AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        UR.ReputationCategory,
        RP.PostId,
        RP.Title,
        RP.Tags,
        PLD.RelatedPostCount,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason
    FROM UserReputation UR
    LEFT JOIN RecentPosts RP ON UR.UserId = RP.OwnerUserId AND RP.PostRank = 1
    LEFT JOIN PostLinksData PLD ON RP.PostId = PLD.PostId
    LEFT JOIN ClosedPosts CP ON RP.PostId = CP.PostId AND CP.CloseEntry = 1
)
SELECT 
    CD.UserId,
    CD.DisplayName,
    CD.Reputation,
    CD.ReputationCategory,
    CD.Title,
    CD.Tags,
    CD.RelatedPostCount,
    CD.CloseReason,
    CASE 
        WHEN CD.CloseReason = 'Not Closed' AND CD.Reputation > 1000 THEN 'Eligible for Promotion'
        ELSE 'Not Eligible for Promotion' 
    END AS PromotionStatus,
    STRING_AGG(T.TagName, ', ') AS TagsList
FROM CombinedData CD
LEFT JOIN (
    SELECT 
        Id AS TagId,
        TagName
    FROM Tags
) T ON POSITION('<' || T.TagName || '>' IN CD.Tags) > 0
GROUP BY 
    CD.UserId, 
    CD.DisplayName, 
    CD.Reputation, 
    CD.ReputationCategory,
    CD.Title, 
    CD.Tags, 
    CD.RelatedPostCount,
    CD.CloseReason
HAVING 
    COUNT(T.TagId) > 2 OR CD.RelatedPostCount > 5
ORDER BY 
    CD.Reputation DESC, 
    CD.Title;
