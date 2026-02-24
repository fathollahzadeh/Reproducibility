
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS TotalCloseVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY U.Id, U.DisplayName
),
HighScoringUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalViews,
        TotalScore,
        TotalCloseVotes,
        RANK() OVER (ORDER BY TotalScore DESC) AS ScoreRank
    FROM UserActivity
    WHERE TotalScore > 100
),
ModeratelyActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS ModerateTotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS ModerateTotalViews
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
    HAVING COUNT(DISTINCT P.Id) >= 5
),
TopActiveModerateUsers AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.ModerateTotalPosts,
        U.ModerateTotalViews,
        RANK() OVER (ORDER BY U.ModerateTotalPosts DESC) AS ActivityRank
    FROM ModeratelyActiveUsers U
    WHERE U.ModerateTotalViews > 100
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2) AS Upvotes,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 3) AS Downvotes
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PD.PostId,
        PD.Title,
        PD.CreationDate,
        PD.Score,
        PD.OwnerDisplayName,
        PD.CommentCount,
        PD.Upvotes,
        PD.Downvotes,
        RANK() OVER (ORDER BY PD.Score DESC) AS PostRank
    FROM PostDetails PD
    WHERE PD.Score > 10
)
SELECT 
    HU.DisplayName AS HighScorer,
    TU.DisplayName AS ModerateUser,
    TP.Title AS TopPostTitle,
    TP.Score AS TopPostScore,
    TP.CommentCount AS TopPostCommentCount
FROM HighScoringUsers HU
FULL OUTER JOIN TopActiveModerateUsers TU ON HU.UserId = TU.UserId
FULL OUTER JOIN TopPosts TP ON TU.UserId IS NOT NULL
WHERE (HU.ScoreRank <= 10 OR TU.ActivityRank <= 10) 
ORDER BY HU.ScoreRank, TU.ActivityRank, TP.PostRank;
