
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.Score,
        p.ViewCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS LatestEditRank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.Score, p.ViewCount
),

RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        ht.Name AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    WHERE 
        ht.Id IN (4, 5, 6, 10, 11) 
),

PostMetrics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        COALESCE(ROUND(AVG(v.BountyAmount), 2), 0) AS AvgBounty,
        COALESCE(ROUND(AVG(CASE WHEN v.VoteTypeId = 2 THEN 1.0 ELSE 0.0 END), 2), 0) AS AvgUpvotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.Tags, rp.Score, rp.ViewCount, rp.AnswerCount
)

SELECT 
    pm.PostId,
    pm.Title,
    pm.Body,
    pm.Tags,
    pm.Score,
    pm.ViewCount,
    pm.AnswerCount,
    pm.AvgBounty,
    pm.AvgUpvotes,
    re.UserId AS LastEditedById,
    re.UserDisplayName AS LastEditedBy,
    re.CreationDate AS LastEditDate,
    re.Comment AS LastEditComment,
    re.HistoryType AS LastEditType
FROM 
    PostMetrics pm
LEFT JOIN 
    RecentEdits re ON pm.PostId = re.PostId
ORDER BY 
    pm.ViewCount DESC,
    pm.Score DESC
FETCH FIRST 50 ROWS ONLY;
