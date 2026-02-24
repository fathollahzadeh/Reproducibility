
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PopularityRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
), UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
), PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment,
        COUNT(CASE WHEN pht.Name = 'Post Closed' THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN pht.Name = 'Post Reopened' THEN 1 END) AS ReopenCount
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.CreationDate, ph.Comment
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalAnswers,
    ua.TotalQuestions,
    rp.Title,
    rp.CreationDate AS PostCreationDate,
    rp.Score,
    rp.ViewCount,
    COALESCE(pHi.CloseCount, 0) AS CloseCount,
    COALESCE(pHi.ReopenCount, 0) AS ReopenCount,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus
FROM 
    UserActivity ua
JOIN 
    RankedPosts rp ON ua.UserId = rp.AcceptedAnswerId
LEFT JOIN 
    PostHistoryInfo pHi ON rp.PostId = pHi.PostId
WHERE 
    ua.TotalPosts > 5
    AND rp.PopularityRank <= 5
ORDER BY 
    ua.TotalPosts DESC, rp.Score DESC;
