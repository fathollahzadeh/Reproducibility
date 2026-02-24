WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM
        Posts p
    JOIN
        Users U ON p.OwnerUserId = U.Id
    WHERE
        p.PostTypeId = 1 
),
TopPostsPerTag AS (
    SELECT
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        Tags
    FROM
        RankedPosts
    WHERE
        TagRank = 1
),
PostCommentStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY
        p.Id
)
SELECT
    t.PostId,
    t.Title,
    t.CreationDate,
    t.Score,
    t.OwnerDisplayName,
    t.Tags,
    pcs.CommentCount,
    pcs.TotalBountyAmount
FROM
    TopPostsPerTag t
JOIN
    PostCommentStats pcs ON t.PostId = pcs.PostId
ORDER BY
    t.CreationDate DESC, pcs.TotalBountyAmount DESC;