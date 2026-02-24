WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        P.LastActivityDate,
        U.DisplayName AS OwnerDisplayName,
        P.LastEditorDisplayName,
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T 
         WHERE P.Tags LIKE '%' || T.TagName || '%') AS Tags 
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
),
HistoricalEdits AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT PH.Comment, '; ') AS EditComments
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.TotalPosts,
    US.TotalComments,
    US.TotalQuestions,
    US.TotalAnswers,
    US.GoldBadges,
    US.SilverBadges,
    US.BronzeBadges,
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.LastActivityDate,
    PS.OwnerDisplayName,
    PS.LastEditorDisplayName,
    PS.Tags,
    HE.EditCount,
    HE.LastEditDate,
    HE.EditComments
FROM UserStats US
JOIN PostStats PS ON US.UserId = PS.PostId
LEFT JOIN HistoricalEdits HE ON PS.PostId = HE.PostId
ORDER BY US.Reputation DESC, PS.Score DESC;
