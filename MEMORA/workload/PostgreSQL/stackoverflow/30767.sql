
WITH RECURSIVE UserReputation AS (
    
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
RecentPosts AS (
    
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.Score AS PostScore,
        COALESCE((SELECT COUNT(*) FROM Posts A WHERE A.ParentId = P.Id AND A.PostTypeId = 2), 0) AS AnswerCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
),
PostHistoryAnalytics AS (
    
    SELECT 
        PH.PostId,
        P.Title,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.Reputation,
    R.BadgeCount,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS PostCreationDate,
    RP.PostScore,
    PH.PostHistoryTypeId,
    PH.HistoryDate
FROM UserReputation R
JOIN RecentPosts RP ON R.UserId = RP.OwnerUserId
LEFT JOIN PostHistoryAnalytics PH ON RP.PostId = PH.PostId AND PH.EditRank = 1
WHERE R.Reputation > 1000 
ORDER BY R.Reputation DESC, RP.CreationDate DESC
LIMIT 100;
