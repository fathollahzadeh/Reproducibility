WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY U.Reputation DESC) AS Rank
    FROM Users U
    WHERE U.Reputation IS NOT NULL 
      AND U.CreationDate < (cast('2024-10-01' as date) - INTERVAL '1 year')
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.CreationDate,
        P.Title,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON C.PostId = P.Id
    WHERE P.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '30 days')
    GROUP BY P.Id, P.OwnerUserId, P.CreationDate, P.Title, P.ViewCount, P.Score
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS HistoryCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS HistoryTypes
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
),
TopPostStats AS (
    SELECT 
        R.UserId,
        R.DisplayName,
        RP.PostId,
        RP.Title,
        RP.ViewCount,
        RP.Score,
        COALESCE(PH.HistoryCount, 0) AS HistoryCount,
        PH.HistoryTypes
    FROM RankedUsers R
    JOIN RecentPosts RP ON R.UserId = RP.OwnerUserId
    LEFT JOIN PostHistoryStats PH ON RP.PostId = PH.PostId
    WHERE R.Rank = 1
),
FilteredPosts AS (
    SELECT 
        T.UserId,
        T.PostId,
        T.Title,
        T.Score,
        T.ViewCount,
        T.HistoryCount,
        T.HistoryTypes,
        CASE 
            WHEN T.HistoryCount > 0 THEN 'Active'
            ELSE 'Inactive'
        END AS PostStatus
    FROM TopPostStats T
    WHERE T.Score > 5 
)

SELECT 
    F.UserId,
    F.PostId,
    F.Title,
    F.ViewCount,
    F.Score,
    F.HistoryCount,
    F.HistoryTypes,
    F.PostStatus,
    CASE 
        WHEN F.Score IS NULL THEN 'No Score'
        WHEN F.Score = 0 THEN 'No Votes'
        WHEN F.Score > 0 AND F.Score <= 10 THEN 'Low Engagement'
        ELSE 'High Engagement'
    END AS EngagementLevel
FROM FilteredPosts F
ORDER BY F.Score DESC, F.ViewCount ASC;