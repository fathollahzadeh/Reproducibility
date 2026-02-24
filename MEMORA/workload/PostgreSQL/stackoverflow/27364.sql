
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastActivityDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN p.Tags) > 0
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, u.DisplayName
),
PostHistoryDetail AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryDate,
        pht.Name AS HistoryType,
        ph.Comment,
        ph.Text
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11, 12) 
),
DetailedView AS (
    SELECT 
        rp.*,
        p_hd.HistoryDate,
        p_hd.HistoryType,
        p_hd.Comment,
        p_hd.Text
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostHistoryDetail p_hd ON rp.PostId = p_hd.PostId
)
SELECT 
    dv.PostId,
    dv.Title,
    dv.Body,
    dv.CreationDate,
    dv.ViewCount,
    dv.Score,
    dv.Tags,
    dv.CommentCount,
    dv.OwnerDisplayName,
    dv.HistoryType,
    dv.HistoryDate,
    dv.Comment,
    dv.Text
FROM 
    DetailedView dv
WHERE 
    dv.rn = 1 
ORDER BY 
    dv.CreationDate DESC, dv.ViewCount DESC
LIMIT 100;
