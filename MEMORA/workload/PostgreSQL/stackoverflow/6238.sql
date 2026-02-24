WITH RecentPostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(u.DisplayName, 'Community User') AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT ParentId, COUNT(*) AS AnswerCount FROM Posts WHERE PostTypeId = 2 GROUP BY ParentId) a ON p.Id = a.ParentId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    AND 
        p.PostTypeId = 1
),
TopTags AS (
    SELECT 
        Tags,
        COUNT(*) AS PostCount
    FROM 
        RecentPostStats
    GROUP BY 
        Tags
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
FilteredPosts AS (
    SELECT 
        r.* 
    FROM 
        RecentPostStats r
    JOIN 
        TopTags t ON r.Tags = t.Tags
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.AnswerCount,
    fp.OwnerDisplayName,
    fp.Tags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.Score DESC, 
    fp.CreationDate DESC;