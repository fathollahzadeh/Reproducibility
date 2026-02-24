WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users U ON p.OwnerUserId = U.Id
),
TopPosts AS (
    SELECT
        *,
        COUNT(*) OVER () AS TotalPosts
    FROM
        RankedPosts
    WHERE
        PostRank <= 100
)
SELECT
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    FavoriteCount,
    OwnerDisplayName,
    TotalPosts
FROM
    TopPosts
ORDER BY
    Score DESC, CreationDate DESC;