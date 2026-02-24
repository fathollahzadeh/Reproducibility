
WITH KeywordAnalysis AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        COALESCE(NULLIF(TRIM(LOWER(p.Title)), ''), '<no title>') AS KeywordTitle,
        COALESCE(NULLIF(TRIM(LOWER(p.Body)), ''), '<no body>') AS KeywordBody,
        LOWER(p.Tags) AS KeywordTags,
        ph.UserDisplayName AS LastEditedBy,
        ph.CreationDate AS LastEditDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, ph.UserDisplayName, ph.CreationDate
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
FinalAnalysis AS (
    SELECT 
        ka.PostId,
        ka.Title,
        ka.Body,
        ka.KeywordTitle,
        ka.KeywordBody,
        ka.KeywordTags,
        ka.LastEditedBy,
        ka.LastEditDate,
        ka.CommentCount,
        ka.UpvoteCount,
        ka.DownvoteCount,
        ts.TagName AS AssociatedTag,
        ts.TotalPosts,
        ts.PostCount
    FROM 
        KeywordAnalysis ka
    LEFT JOIN 
        TagStatistics ts ON ka.KeywordTags LIKE '%' || ts.TagName || '%'
)
SELECT 
    PostId,
    Title,
    Body,
    KeywordTitle,
    KeywordBody,
    AssociatedTag,
    LastEditedBy,
    LastEditDate,
    CommentCount,
    UpvoteCount,
    DownvoteCount,
    TotalPosts,
    PostCount
FROM 
    FinalAnalysis
WHERE 
    UpvoteCount > DownvoteCount
ORDER BY 
    UpvoteCount DESC, LastEditDate DESC
LIMIT 50;
