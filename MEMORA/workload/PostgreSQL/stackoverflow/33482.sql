WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0     
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeQuestions,
        MAX(p.CreationDate) AS LastQuestionDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id
),
PostHistoryRecords AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
),
PostCloseReasonCounts AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS CloseReason
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.QuestionCount,
    ua.PositiveQuestions,
    ua.NegativeQuestions,
    ua.LastQuestionDate,
    COUNT(DISTINCT rp.PostId) AS RecentQuestionCount,
    COALESCE(pcrc.CloseReason, 'Not Closed') AS CloseReason,
    SUM(ph.HistoryCount) AS TotalHistoryCount
FROM 
    UserActivity ua
LEFT JOIN 
    RankedPosts rp ON ua.UserId = rp.OwnerUserId AND rp.PostRank <= 5  
LEFT JOIN 
    PostCloseReasonCounts pcrc ON rp.PostId = pcrc.PostId
LEFT JOIN 
    PostHistoryRecords ph ON rp.PostId = ph.PostId
GROUP BY 
    ua.UserId, ua.DisplayName, ua.Reputation, 
    ua.QuestionCount, ua.PositiveQuestions, ua.NegativeQuestions, 
    ua.LastQuestionDate, pcrc.CloseReason
ORDER BY 
    ua.Reputation DESC, RecentQuestionCount DESC;