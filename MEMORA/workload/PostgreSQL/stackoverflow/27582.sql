WITH QualifiedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'), 1) AS TagCount,
        u.DisplayName AS OwnerDisplayName,
        COALESCE((
            SELECT COUNT(*)
            FROM Posts AS a
            WHERE a.ParentId = p.Id
        ), 0) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0 AND
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 24) 
    GROUP BY 
        ph.PostId
),
ClosedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory
    WHERE 
        PostHistoryTypeId = 10 
    GROUP BY 
        PostId
)
SELECT 
    qp.PostId,
    qp.Title,
    qp.OwnerDisplayName,
    qp.Score,
    qp.ViewCount,
    qp.TagCount,
    COALESCE(phe.EditCount, 0) AS EditCount,
    COALESCE(cp.CloseCount, 0) AS CloseCount
FROM 
    QualifiedPosts qp
LEFT JOIN 
    PostHistoryStats phe ON qp.PostId = phe.PostId
LEFT JOIN 
    ClosedPosts cp ON qp.PostId = cp.PostId
ORDER BY 
    qp.Score DESC, qp.ViewCount DESC, qp.CreationDate ASC;