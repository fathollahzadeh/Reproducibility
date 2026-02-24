WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
      AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 YEAR'
),

ClosedPosts AS (
    SELECT 
        ph.PostId, 
        ph.CreationDate AS CloseDate, 
        ph.UserDisplayName AS ClosedBy, 
        ph.Comment AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10 
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate AS QuestionDate,
    rp.Score AS QuestionScore,
    rp.ViewCount AS QuestionViews,
    rp.AnswerCount AS TotalAnswers,
    cp.CloseDate,
    cp.ClosedBy,
    cp.CloseReason,
    CASE 
        WHEN rp.OwnerReputation > 1000 THEN 'Experienced'
        ELSE 'Newbie'
    END AS UserExperienceLevel
FROM 
    RankedPosts rp
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.Rank = 1 
ORDER BY 
    rp.Score DESC NULLS LAST,
    rp.ViewCount DESC;