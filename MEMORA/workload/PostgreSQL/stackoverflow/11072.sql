
WITH PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentTotal,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= '2022-01-01'  
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score, 
             P.AnswerCount, P.CommentCount, P.FavoriteCount, 
             U.DisplayName
),
UserStats AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
)
SELECT
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.OwnerDisplayName,
    PS.CommentTotal,
    PS.UpVotes,
    PS.DownVotes,
    US.UserId,
    US.DisplayName AS UserDisplayName,
    US.BadgeCount,
    US.TotalUpVotes AS UserTotalUpVotes,
    US.TotalDownVotes AS UserTotalDownVotes
FROM PostStats PS
JOIN UserStats US ON PS.OwnerDisplayName = US.DisplayName
ORDER BY PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
