
WITH DetailedPostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2 
    LEFT JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, LENGTH(p.Tags) - 2), '>')) AS t(TagName) ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, u.Reputation
),
PostHistoryAnalysis AS (
    SELECT
        ph.PostId,
        MIN(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS FirstClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS TotalCloseVotes,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS TotalReopenVotes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    dpi.PostId,
    dpi.Title,
    dpi.Body,
    dpi.CreationDate,
    dpi.Score,
    dpi.ViewCount,
    dpi.OwnerDisplayName,
    dpi.OwnerReputation,
    dpi.Tags,
    dpi.CommentCount,
    dpi.AnswerCount,
    pha.FirstClosedDate,
    pha.LastClosedDate,
    pha.TotalCloseVotes,
    pha.TotalReopenVotes
FROM 
    DetailedPostInfo dpi
LEFT JOIN 
    PostHistoryAnalysis pha ON dpi.PostId = pha.PostId
ORDER BY 
    dpi.CreationDate DESC
LIMIT 50;
