WITH RECURSIVE TopTags AS (
    SELECT 
        Tags.Id,
        Tags.TagName,
        Tags.Count,
        1 AS Level
    FROM Tags
    WHERE Tags.Count > 1000

    UNION ALL

    SELECT 
        Tags.Id,
        Tags.TagName,
        Tags.Count,
        Level + 1
    FROM Tags
    INNER JOIN TopTags ON Tags.Count > TopTags.Count
    WHERE TopTags.Level < 5
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS PostCount,
        SUM(COALESCE(Posts.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(Posts.Score, 0)) AS TotalScore
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    WHERE Users.Reputation > 500
    GROUP BY Users.Id, Users.DisplayName
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate, 
        PH.UserId,
        PH.Comment,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 11)
    GROUP BY PH.PostId, PH.CreationDate, PH.UserId, PH.Comment
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.TotalViews,
        UA.TotalScore,
        RANK() OVER (ORDER BY UA.TotalScore DESC) AS ScoreRank,
        RANK() OVER (ORDER BY UA.PostCount DESC) AS PostRank
    FROM UserActivity UA
)
SELECT 
    U.DisplayName AS TopUser,
    U.PostCount,
    U.TotalViews,
    U.TotalScore,
    T.TagName,
    COALESCE(CP.CloseCount, 0) AS TotalClosedPosts
FROM TopUsers U
INNER JOIN TopTags T ON T.Level <= 3
LEFT JOIN ClosedPosts CP ON U.UserId = CP.UserId
WHERE U.ScoreRank <= 10 AND U.PostRank <= 10
ORDER BY U.TotalScore DESC, U.PostCount DESC, T.TagName
LIMIT 50;

