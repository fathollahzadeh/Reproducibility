WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        P.LastActivityDate,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Tags T ON T.ExcerptPostId = P.Id
    WHERE P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY P.Id, U.DisplayName, U.Reputation
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(B.Id) AS BadgeCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalPostViews
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.OwnerDisplayName,
    PS.OwnerReputation,
    PS.LastActivityDate,
    PS.Tags,
    US.TotalPostViews,
    US.BadgeCount
FROM PostStats PS
JOIN UserStats US ON PS.OwnerDisplayName = US.DisplayName
ORDER BY PS.Score DESC, PS.ViewCount DESC
LIMIT 50;