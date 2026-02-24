
WITH RankedTags AS (
    SELECT 
        t.TagName,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(p.Id) AS TagUsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName, p.Id, p.Title, p.CreationDate
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        RankedTags
    GROUP BY 
        TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
DetailedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        STRING_AGG(c.Text, ' || ') AS Comments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.Tags LIKE CONCAT('%', (SELECT STRING_AGG(TagName, '%||%') FROM TopTags), '%')
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.CreationDate, p.Score, p.ViewCount
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    dp.PostId,
    dp.Title,
    dp.CreationDate,
    dp.OwnerDisplayName,
    dp.Score,
    dp.ViewCount,
    pts.Upvotes,
    pts.Downvotes,
    dp.Comments
FROM 
    DetailedPosts dp
LEFT JOIN 
    PostVoteStats pts ON dp.PostId = pts.PostId
ORDER BY 
    dp.CreationDate DESC
LIMIT 10;
