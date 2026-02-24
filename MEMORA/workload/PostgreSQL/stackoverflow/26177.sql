
WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.Body, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, u.DisplayName
),
TagStatistics AS (
    SELECT 
        unnest(string_to_array(trim(both '<>' from Tags), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        FilteredPosts
    GROUP BY 
        unnest(string_to_array(trim(both '<>' from Tags), '><'))
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        RANK() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.CreationDate,
    fp.ViewCount,
    fp.Score,
    fp.CommentCount,
    fp.Upvotes,
    fp.Downvotes,
    tt.TagName,
    tt.TagCount
FROM 
    FilteredPosts fp
JOIN 
    TopTags tt ON tt.TagName = ANY(string_to_array(trim(both '<>' from fp.Tags), '><'))
WHERE 
    tt.TagRank <= 5 
ORDER BY 
    fp.ViewCount DESC, 
    fp.Score DESC;
