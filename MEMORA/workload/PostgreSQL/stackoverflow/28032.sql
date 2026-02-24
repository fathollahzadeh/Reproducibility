
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount  
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.ViewCount, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.UpvoteCount,
        rp.DownvoteCount,
        CASE 
            WHEN rp.ViewCount > 1000 THEN 'High Engagement'
            WHEN rp.ViewCount BETWEEN 500 AND 1000 THEN 'Medium Engagement'
            ELSE 'Low Engagement' 
        END AS EngagementLevel,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON POSITION(CONCAT('<', t.TagName, '>') IN rp.Tags) > 0  
    GROUP BY 
        rp.PostId, rp.Title, rp.Tags, rp.CreationDate, rp.ViewCount, rp.OwnerDisplayName, 
        rp.CommentCount, rp.UpvoteCount, rp.DownvoteCount
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.TagsList,
    fp.CreationDate,
    fp.ViewCount,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.UpvoteCount,
    fp.DownvoteCount,
    fp.EngagementLevel
FROM 
    FilteredPosts fp
WHERE 
    fp.CommentCount > 5 OR fp.UpvoteCount > 10  
ORDER BY 
    fp.ViewCount DESC, fp.CreationDate DESC;
