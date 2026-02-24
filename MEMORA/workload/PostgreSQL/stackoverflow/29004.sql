WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank,
        COUNT(*) OVER (PARTITION BY p.Tags) AS TagCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
),

RecentActivity AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN p.LastActivityDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 1 END) AS RecentCommentCount,
        COUNT(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 END) AS CloseCount
    FROM 
        Posts p
    JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        PostId
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        COALESCE(ra.RecentCommentCount, 0) AS RecentComments,
        COALESCE(ra.CloseCount, 0) AS CloseStatus,
        rp.TagCount,
        rp.TagRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentActivity ra ON rp.PostId = ra.PostId
)

SELECT 
    pm.Title,
    pm.OwnerDisplayName,
    pm.RecentComments,
    pm.CloseStatus,
    pm.TagCount,
    pm.TagRank
FROM 
    PostMetrics pm
WHERE 
    pm.TagRank <= 3  
ORDER BY 
    pm.CloseStatus DESC, 
    pm.RecentComments DESC;