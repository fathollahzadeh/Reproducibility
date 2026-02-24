WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId = 1 
),
FilteredPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        OwnerDisplayName
    FROM
        RankedPosts
    WHERE
        Rank <= 5 
),
PostComments AS (
    SELECT
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM
        Comments c
    GROUP BY
        c.PostId
),
PostScores AS (
    SELECT
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.CreationDate,
        fp.Score,
        fp.OwnerDisplayName,
        COALESCE(pc.CommentCount, 0) AS CommentCount
    FROM
        FilteredPosts fp
    LEFT JOIN
        PostComments pc ON fp.PostId = pc.PostId
),
PostTags AS (
    SELECT
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 
)
SELECT
    ps.PostId,
    ps.Title,
    ps.Body,
    ps.CreationDate,
    ps.Score,
    ps.CommentCount,
    pt.Tag,
    CASE
        WHEN ps.Score >= 100 THEN 'High Score'
        WHEN ps.Score BETWEEN 50 AND 99 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM
    PostScores ps
JOIN
    PostTags pt ON ps.PostId = pt.PostId
ORDER BY
    ps.Score DESC, ps.CreationDate DESC;