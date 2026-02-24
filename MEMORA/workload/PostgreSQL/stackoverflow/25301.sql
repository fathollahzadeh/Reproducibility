WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        DATE_TRUNC('month', p.CreationDate) AS PostMonth,
        RANK() OVER (PARTITION BY DATE_TRUNC('month', p.CreationDate) ORDER BY COUNT(DISTINCT v.Id) DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT
        PostId,
        Title,
        Body,
        Tags,
        Author,
        CommentCount,
        AnswerCount,
        PostMonth
    FROM
        RankedPosts
    WHERE
        PostRank = 1 
)
SELECT
    t.PostId,
    t.Title,
    t.Author,
    t.CommentCount,
    t.AnswerCount,
    t.PostMonth,
    ARRAY_AGG(DISTINCT tr.TagName) AS Tags
FROM
    TopPosts t
LEFT JOIN
    (SELECT 
        DISTINCT UNNEST(string_to_array(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS TagName
     FROM 
        Posts) tr ON tr.TagName ILIKE '%' || t.Tags || '%'
GROUP BY
    t.PostId, t.Title, t.Author, t.CommentCount, t.AnswerCount, t.PostMonth
ORDER BY
    t.PostMonth ASC;