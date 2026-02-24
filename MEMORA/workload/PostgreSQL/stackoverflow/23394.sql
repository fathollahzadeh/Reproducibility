WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
        AND p.ViewCount > 0
),
TagCounts AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t 
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(DISTINCT p.Id) >= 5
),
UserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(p.Score) AS TotalScore,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '2 year'
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) >= 10
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 END) AS ChangeCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    tc.TagName,
    us.TotalScore,
    us.QuestionCount,
    ph.CloseDate,
    ph.ReopenDate,
    ph.ChangeCount
FROM 
    RankedPosts rp
LEFT JOIN 
    TagCounts tc ON tc.PostCount > 3
JOIN 
    UserScores us ON us.QuestionCount >= 5
LEFT JOIN 
    PostHistorySummary ph ON ph.PostId = rp.PostId
WHERE 
    rp.Rank <= 10
    AND (ph.CloseDate IS NULL OR ph.ReopenDate IS NOT NULL)
    AND (ph.ChangeCount IS NOT NULL OR ph.ChangeCount > 0)
ORDER BY 
    rp.Score DESC,
    rp.CreationDate ASC;