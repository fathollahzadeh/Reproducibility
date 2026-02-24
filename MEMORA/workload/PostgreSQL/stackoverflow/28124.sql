WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        u.DisplayName AS OwnerName,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS TotalPosts
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate AS ActivityDate,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, ph.UserDisplayName, ph.CreationDate, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate AS PostDate,
    rp.OwnerName,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    rp.CommentCount,
    rp.Tags,
    pt.TagName AS PopularTag,
    ra.ActivityDate,
    ra.EditCount
FROM 
    RankedPosts rp
LEFT JOIN  
    RecentActivity ra ON rp.PostId = ra.PostId
LEFT JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'
WHERE 
    rp.PostRank <= 100 
ORDER BY 
    rp.CreationDate DESC, 
    rp.Score DESC;