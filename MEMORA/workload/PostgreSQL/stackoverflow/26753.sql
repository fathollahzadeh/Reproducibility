
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC, p.Score DESC) AS PostRank,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.ViewCount, p.Score, p.CreationDate
),
FilteredRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        ViewCount,
        Score,
        CreationDate,
        OwnerDisplayName,
        Tags
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5  
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        p.Title AS CurrentTitle,
        p.Body AS CurrentBody,
        p.Tags AS CurrentTags,
        ph.Comment AS EditComment
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
)

SELECT 
    frp.PostId,
    frp.Title,
    frp.Body,
    frp.ViewCount,
    frp.Score,
    frp.CreationDate,
    frp.OwnerDisplayName,
    frp.Tags,
    PHD.HistoryDate,
    PHD.CurrentTitle,
    PHD.CurrentBody,
    PHD.CurrentTags,
    PHD.EditComment
FROM 
    FilteredRankedPosts frp
LEFT JOIN 
    PostHistoryData PHD ON frp.PostId = PHD.PostId
ORDER BY 
    frp.Score DESC, 
    frp.ViewCount DESC, 
    frp.CreationDate DESC;
