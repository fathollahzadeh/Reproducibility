
WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        1 AS Level
    FROM Users U
    WHERE U.Reputation IS NOT NULL
    
    UNION ALL
    
    SELECT 
        U.Id AS UserId,
        (U.Reputation + COALESCE(SUM(V.BountyAmount), 0)) AS Reputation,
        UR.Level + 1
    FROM Users U
    JOIN Votes V ON U.Id = V.UserId
    JOIN UserReputation UR ON UR.UserId = V.UserId
    GROUP BY U.Id, UR.Level
),
PostsWithTags AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        T.TagName,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.Score DESC) AS TagRank
    FROM Posts P
    LEFT JOIN Tags T ON P.Tags LIKE '%' || T.TagName || '%'
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Date) AS LastBadgeDate
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CR.Name, ', ') AS CloseReasonNames,
        COUNT(*) AS CloseCount
    FROM PostHistory PH
    JOIN CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE PH.PostHistoryTypeId IN (10, 11)
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    UB.BadgeCount,
    PT.TagName,
    PT.Title AS PostTitle,
    PT.CreationDate AS PostCreationDate,
    PT.Score AS PostScore,
    CR.CloseReasonNames,
    CR.CloseCount,
    ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY PT.CreationDate DESC) AS RecentPostRank
FROM Users U
JOIN UserBadges UB ON U.Id = UB.UserId
JOIN PostsWithTags PT ON U.Id = PT.OwnerUserId
LEFT JOIN CloseReasons CR ON PT.PostId = CR.PostId
WHERE U.Reputation >= 1000
    AND PT.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days'
    AND (UB.BadgeCount IS NULL OR UB.BadgeCount > 2)
ORDER BY U.Reputation DESC, PT.CreationDate DESC;
