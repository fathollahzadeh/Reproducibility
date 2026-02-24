WITH UserStats AS (
    SELECT
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(COALESCE(P.Score, 0)) AS TotalScore
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation, U.CreationDate, U.DisplayName
),
PostActivity AS (
    SELECT
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.OwnerUserId, P.PostTypeId
),
PostHistoryStats AS (
    SELECT
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        COUNT(DISTINCT PH.UserId) AS UniqueEditors
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    U.TotalViews,
    U.TotalPosts,
    U.TotalScore,
    PA.CommentCount,
    PA.VoteCount,
    COALESCE(PH.EditCount, 0) AS EditCount,
    COALESCE(PH.UniqueEditors, 0) AS UniqueEditors
FROM UserStats U
LEFT JOIN PostActivity PA ON U.UserId = PA.OwnerUserId
LEFT JOIN PostHistoryStats PH ON PA.PostId = PH.PostId
ORDER BY U.Reputation DESC, U.TotalScore DESC;