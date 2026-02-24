
WITH TaggedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpVoteCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 
    WHERE p.PostTypeId = 1 
    GROUP BY p.Id, p.Title, p.Body, p.CreationDate, p.Tags, u.DisplayName
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName, 
        COUNT(*) AS TagCount
    FROM TaggedPosts
    GROUP BY TagName
),
TopTags AS (
    SELECT TagName 
    FROM PopularTags 
    WHERE TagCount > 10 
    ORDER BY TagCount DESC
    LIMIT 5
),
Benchmarking AS (
    SELECT
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpVoteCount,
        pt.TagName
    FROM TaggedPosts tp
    JOIN TopTags pt ON tp.Tags LIKE '%' || pt.TagName || '%'
    ORDER BY tp.UpVoteCount DESC, tp.CommentCount DESC
    LIMIT 10
)
SELECT 
    b.PostId,
    b.Title,
    b.Body,
    b.OwnerDisplayName,
    b.CommentCount,
    b.UpVoteCount,
    b.TagName,
    CASE 
        WHEN b.CommentCount > 5 THEN 'High Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM Benchmarking b
ORDER BY b.UpVoteCount DESC;
