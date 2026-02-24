
WITH RankedUserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        RANK() OVER (PARTITION BY CASE WHEN U.Reputation >= 1000 THEN 1 ELSE 0 END ORDER BY COUNT(P.Id) DESC) AS RankByPostCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    WHERE U.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
LatestPostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RowNum
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 month' 
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM Badges B
    GROUP BY B.UserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Comment,
        PH.CreationDate,
        PH.UserId,
        PH.PostHistoryTypeId
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
),
FilteredPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        COALESCE(CP.Comment, 'No comment provided') AS CloseComment,
        CASE
            WHEN CP.PostId IS NOT NULL AND CP.PostHistoryTypeId = 10 THEN 'Closed'
            WHEN CP.PostId IS NOT NULL AND CP.PostHistoryTypeId = 11 THEN 'Reopened'
            ELSE 'Active'
        END AS PostStatus,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN ClosedPosts CP ON P.Id = CP.PostId
)
SELECT 
    RUP.DisplayName,
    RUP.PostCount,
    LPD.Title AS LatestPostTitle,
    LPD.CreationDate AS LatestPostDate,
    LPD.Score AS LatestPostScore,
    UBD.BadgeNames,
    FPT.ViewCount AS FilteredPostViewCount,
    FPT.CloseComment,
    FPT.PostStatus
FROM RankedUserPostCounts RUP
JOIN LatestPostDetails LPD ON RUP.UserId = LPD.OwnerUserId AND LPD.RowNum = 1
LEFT JOIN UserBadges UBD ON RUP.UserId = UBD.UserId
LEFT JOIN FilteredPosts FPT ON RUP.UserId = FPT.OwnerUserId
WHERE RUP.RankByPostCount = 1 
ORDER BY RUP.PostCount DESC, RUP.DisplayName ASC;
