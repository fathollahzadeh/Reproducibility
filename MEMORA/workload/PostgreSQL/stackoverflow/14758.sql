WITH PostStats AS (
    SELECT
        P.Id AS PostId,
        P.PostTypeId,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.Title,
        P.Tags,
        U.Reputation AS OwnerReputation,
        U.CreationDate AS OwnerCreationDate
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
),
TopPosts AS (
    SELECT
        PostId,
        PostTypeId,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        CommentCount,
        Title,
        Tags,
        OwnerReputation,
        OwnerCreationDate,
        RANK() OVER (PARTITION BY PostTypeId ORDER BY Score DESC) AS ScoreRank
    FROM
        PostStats
)
SELECT
    PostId,
    PostTypeId,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    Title,
    Tags,
    OwnerReputation,
    OwnerCreationDate
FROM
    TopPosts
WHERE
    ScoreRank <= 10
ORDER BY
    PostTypeId, Score DESC;