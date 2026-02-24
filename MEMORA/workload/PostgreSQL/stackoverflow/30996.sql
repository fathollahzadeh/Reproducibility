WITH RECURSIVE UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        MAX(B.Class) AS HighestBadgeClass
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
PostViewCounts AS (
    SELECT 
        P.OwnerUserId,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(P.Id) AS TotalPosts
    FROM Posts P
    GROUP BY P.OwnerUserId
),
RecentEdits AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditOrder
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) 
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(DISTINCT CR.Name, ', ') AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CR ON PH.Comment = CR.Id::text
    WHERE PH.PostHistoryTypeId = 10
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName,
    COALESCE(UB.BadgeCount, 0) AS BadgeCount,
    COALESCE(UB.HighestBadgeClass, 0) AS HighestBadgeClass,
    COALESCE(PV.TotalViews, 0) AS TotalViews,
    COALESCE(PV.TotalPosts, 0) AS TotalPosts,
    COALESCE(RE.EditCount, 0) AS RecentEdits,
    COALESCE(CP.CloseCount, 0) AS ClosedPostCount,
    COALESCE(CP.CloseReasons, 'No reasons') AS CloseReasons
FROM Users U
LEFT JOIN UserBadgeCounts UB ON U.Id = UB.UserId
LEFT JOIN PostViewCounts PV ON U.Id = PV.OwnerUserId
LEFT JOIN (SELECT PostId, COUNT(*) AS EditCount FROM RecentEdits WHERE EditOrder <= 3 GROUP BY PostId) RE ON RE.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
LEFT JOIN ClosedPosts CP ON CP.PostId IN (SELECT P.Id FROM Posts P WHERE P.OwnerUserId = U.Id)
WHERE U.Reputation > 1000 
ORDER BY U.DisplayName;