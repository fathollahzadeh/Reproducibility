WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        COALESCE(NULLIF(u.DisplayName, ''), 'Anonymous') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND p.Score > 0
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount,
        SUM(CASE WHEN pt.Score > 10 THEN 1 ELSE 0 END) AS HighScorePosts
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        p.Title,
        ph.CreationDate AS EditDate,
        ph.Comment,
        p.ViewCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5) 
        AND ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)
SELECT 
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate AS PostCreationDate,
    rp.ViewCount,
    rp.Score,
    rp.AnswerCount,
    ts.TagName,
    ts.PostCount,
    ts.HighScorePosts,
    ph.EditDate,
    ph.Comment AS EditComment
FROM 
    RankedPosts rp
LEFT JOIN 
    TagStats ts ON ts.PostCount > 5
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;