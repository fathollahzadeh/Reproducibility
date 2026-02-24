
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        p.AnswerCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 5
),
RecentCloseReasons AS (
    SELECT 
        ph.PostId,
        ARRAY_AGG(DISTINCT ctr.Name) AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON CAST(ph.Comment AS INTEGER) = ctr.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) AND ph.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 month'
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerName,
    rp.CreationDate,
    rp.Score,
    COALESCE(rcr.CloseReasons, ARRAY['No recent close reasons']) AS CloseReasons,
    CASE 
        WHEN rp.AnswerCount = 0 THEN 'No Answers Yet'
        WHEN rp.AnswerCount >= 5 THEN 'Popular Question'
        ELSE 'Moderate Engagement'
    END AS EngagementLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentCloseReasons rcr ON rp.PostId = rcr.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 50;
