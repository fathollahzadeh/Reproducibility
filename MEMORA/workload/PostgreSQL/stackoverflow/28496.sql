WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        COALESCE(a.AcceptedAnswerId, -1) AS AcceptedAnswerId
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, 
        p.Score, u.DisplayName, a.AcceptedAnswerId
),
HistoricalEdits AS (
    SELECT 
        ph.PostId,
        STRING_AGG(CONCAT(ph.CreationDate, ': ', ph.Comment), ' | ') AS EditHistory,
        COUNT(*) AS EditCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId
),
PopularityMetrics AS (
    SELECT 
        p.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        PostDetails p
    LEFT JOIN 
        Votes v ON p.PostId = v.PostId
    GROUP BY 
        p.PostId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.Body,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    pd.OwnerDisplayName,
    pd.Tags,
    COALESCE(he.EditHistory, 'No edits') AS EditHistory,
    COALESCE(he.EditCount, 0) AS EditCount,
    pm.VoteCount,
    pm.UpVotes,
    pm.DownVotes
FROM 
    PostDetails pd
LEFT JOIN 
    HistoricalEdits he ON pd.PostId = he.PostId
LEFT JOIN 
    PopularityMetrics pm ON pd.PostId = pm.PostId
ORDER BY 
    pd.ViewCount DESC, pd.CreationDate DESC
LIMIT 50;