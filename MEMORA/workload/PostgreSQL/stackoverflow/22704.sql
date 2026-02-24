WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.Score IS NOT NULL THEN P.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN P.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS NonDeletedPosts,
        AVG(P.ViewCount) AS AverageViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
CloseReasons AS (
    SELECT 
        PH.UserId,
        COUNT(PH.Id) AS CloseCount,
        STRING_AGG(CASE 
            WHEN PH.Comment IS NOT NULL THEN PH.Comment 
            ELSE 'No Reason Provided' 
        END, ', ') AS Reasons
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY PH.UserId
),
BadgesSummary AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS TotalBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        COUNT(C.Id) AS CommentCount,
        SUM(COALESCE(C.Score, 0)) AS CommentScore,
        P.OwnerUserId
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id, P.OwnerUserId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalScore,
    UA.NonDeletedPosts,
    UA.AverageViews,
    COALESCE(CR.CloseCount, 0) AS CloseCount,
    COALESCE(CR.Reasons, 'No Close Actions') AS CloseReasons,
    COALESCE(BS.BadgeNames, 'No Badges') AS BadgeNames,
    COALESCE(BS.TotalBadges, 0) AS TotalBadges,
    PWC.CommentCount,
    PWC.CommentScore
FROM UserActivity UA
LEFT JOIN CloseReasons CR ON UA.UserId = CR.UserId
LEFT JOIN BadgesSummary BS ON UA.UserId = BS.UserId
LEFT JOIN PostsWithComments PWC ON UA.UserId = PWC.OwnerUserId
WHERE UA.TotalPosts > 5
  AND UA.AverageViews > 10
  AND (CR.CloseCount IS NULL OR CR.CloseCount < 3)
ORDER BY UA.TotalScore DESC, UA.DisplayName ASC
LIMIT 50;