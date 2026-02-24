
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS AuthorDisplayName,
        COUNT(a.Id) AS AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate, p.Score
), RecentActivities AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ph.UserDisplayName || ' ' || ph.Comment, '; ') AS ModComments,
        COUNT(*) AS ModificationCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= CURRENT_DATE - INTERVAL '3 months'  
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Tags,
    rp.CreationDate,
    rp.AuthorDisplayName,
    rp.AnswerCount,
    rp.Score,
    ra.ModComments,
    ra.ModificationCount
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentActivities ra ON rp.PostId = ra.PostId
WHERE 
    rp.TagRank = 1  
ORDER BY 
    rp.CreationDate DESC;
