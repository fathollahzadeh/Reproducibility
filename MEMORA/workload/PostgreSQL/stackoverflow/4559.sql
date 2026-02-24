WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount,
        AVG(a.Score) AS AvgScore
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        CASE 
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            ELSE 'Other'
        END AS ChangeType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.AnswerCount AS TotalAnswers,
    COALESCE(a.AnswerCount, 0) AS TotalAnswersFromStats,
    COALESCE(a.AvgScore, 0) AS AvgAnswerScore,
    ph.ChangeType,
    ph.CreationDate AS ChangeDate
FROM 
    RankedPosts rp
LEFT JOIN 
    AnswerStats a ON rp.PostId = a.PostId
LEFT JOIN 
    PostHistoryDetails ph ON rp.PostId = ph.PostId
WHERE 
    rp.OwnerPostRank = 1 
    AND (ph.ChangeType IS NULL OR ph.ChangeType = 'Closed/Reopened')
ORDER BY 
    rp.CreationDate DESC;