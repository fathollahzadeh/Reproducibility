
WITH PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        P.CreationDate,
        U.Reputation AS OwnerReputation
    FROM
        Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
    GROUP BY
        P.Id, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, P.FavoriteCount, P.CreationDate, U.Reputation
),
PostHistoryStats AS (
    SELECT
        PH.PostId,
        COUNT(*) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionCount
    FROM
        PostHistory PH
    GROUP BY
        PH.PostId
)

SELECT
    PS.PostId,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.CreationDate,
    PS.OwnerReputation,
    COALESCE(PHS.EditCount, 0) AS EditCount,
    COALESCE(PHS.CloseCount, 0) AS CloseCount,
    COALESCE(PHS.DeletionCount, 0) AS DeletionCount
FROM
    PostStats PS
LEFT JOIN PostHistoryStats PHS ON PS.PostId = PHS.PostId
ORDER BY
    PS.Score DESC,
    PS.ViewCount DESC;
