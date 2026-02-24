
WITH PostTagCounts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName,
        COUNT(v.Id) AS VoteCount
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title
),
RankedTags AS (
    SELECT
        TagName,
        COUNT(PostId) AS TagPostCount,
        SUM(VoteCount) AS TotalVotes,
        RANK() OVER (ORDER BY SUM(VoteCount) DESC) AS TagRank
    FROM
        PostTagCounts
    GROUP BY
        TagName
),
TopTags AS (
    SELECT
        TagName
    FROM
        RankedTags
    WHERE
        TagRank <= 5
),
TopPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM
        Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    INNER JOIN PostTagCounts pt ON p.Id = pt.PostId
    INNER JOIN TopTags tt ON pt.TagName = tt.TagName
    WHERE
        p.PostTypeId = 1  
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount
    ORDER BY
        CommentCount DESC, ViewCount DESC
    LIMIT 10
)
SELECT
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    ARRAY_AGG(pt.TagName) AS AssociatedTags
FROM
    TopPosts tp
JOIN
    PostTagCounts pt ON tp.Id = pt.PostId
GROUP BY
    tp.Title, tp.CreationDate, tp.ViewCount, tp.CommentCount
ORDER BY
    tp.CommentCount DESC, tp.ViewCount DESC;
