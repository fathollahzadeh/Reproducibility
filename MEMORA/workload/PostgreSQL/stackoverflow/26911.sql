
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY u.Location ORDER BY p.CreationDate DESC) AS LocationRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND u.Location IS NOT NULL
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(Tags, ','))
    HAVING 
        COUNT(*) > 5 
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id
)
SELECT 
    r.PostId,
    r.Title,
    r.Body,
    r.OwnerDisplayName,
    r.AcceptedAnswerId,
    rt.TagName,
    a.CommentCount,
    a.Upvotes,
    a.Downvotes,
    r.LocationRank
FROM 
    RankedPosts r
JOIN 
    PopularTags rt ON POSITION(rt.TagName IN r.Body) > 0
JOIN 
    RecentActivity a ON r.PostId = a.PostId
WHERE 
    r.LocationRank <= 5 
ORDER BY 
    r.LocationRank, a.Upvotes DESC, a.CommentCount DESC;
