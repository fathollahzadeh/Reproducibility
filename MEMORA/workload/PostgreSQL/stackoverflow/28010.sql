WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS TagCount,
        SUM(l.Count) AS TagUsageCount
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN 
        Tags l ON t.Id = l.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(pa.Id) AS AnswerCount,
        AVG(pa.Score) AS AvgAnswerScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts pa ON p.Id = pa.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
PostHistoryAnalytics AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN ph.CreationDate END) AS LastEditDate,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10) THEN ph.CreationDate END) AS ClosedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    pt.TagCount,
    pt.TagUsageCount,
    asn.AnswerCount,
    asn.AvgAnswerScore,
    ph.EditCount,
    ph.LastEditDate,
    ph.ClosedDate
FROM 
    Posts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    PostTagCounts pt ON p.Id = pt.PostId
LEFT JOIN 
    AnswerStats asn ON p.Id = asn.PostId
LEFT JOIN 
    PostHistoryAnalytics ph ON p.Id = ph.PostId
WHERE 
    p.Score > 10 
ORDER BY 
    p.CreationDate DESC
LIMIT 100;