
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        SUM(U.Views) AS TotalViews,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        COUNT(C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
),
PostSummary AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.LastActivityDate,
        PT.Name AS PostTypeName,
        P.OwnerUserId  -- Added OwnerUserId for proper join
    FROM Posts P
    JOIN PostTypes PT ON P.PostTypeId = PT.Id
)
SELECT 
    UA.DisplayName,
    UA.PostCount,
    UA.TotalScore,
    UA.TotalViews,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    UA.CommentCount,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount AS PostCommentCount,
    PS.FavoriteCount,
    PS.LastActivityDate,
    PS.PostTypeName
FROM UserActivity UA
LEFT JOIN PostSummary PS ON UA.UserId = PS.OwnerUserId
ORDER BY UA.TotalScore DESC, UA.PostCount DESC
LIMIT 100;
