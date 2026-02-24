WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        u.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId IN (1, 2)  
),
AggregatedTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount,
        SUM(pt.ViewCount) AS TotalViews
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserDisplayName,
        ph.CreationDate,
        STRING_AGG(DISTINCT p.Title, ', ') AS RelatedPosts
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24)  
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserDisplayName, ph.CreationDate
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Author,
    rp.AnswerCount,
    rp.ViewCount,
    ag.TagName,
    ag.PostCount,
    ag.TotalViews,
    re.UserDisplayName AS Editor,
    re.CreationDate AS EditDate,
    re.RelatedPosts
FROM 
    RankedPosts rp
LEFT JOIN 
    AggregatedTags ag ON ag.PostCount > 0  
LEFT JOIN 
    RecentEdits re ON re.PostId = rp.PostId
WHERE 
    rp.PostRank = 1  
ORDER BY 
    rp.CreationDate DESC;