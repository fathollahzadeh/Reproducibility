
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Body,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestionsAsked,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS UpvotedAnswers,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedAnswers,
        AVG(p.ViewCount) AS AvgViewsPerQuestion
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName
),

CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment AS CloseReason,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId, ph.Comment
)

SELECT 
    u.DisplayName AS User,
    ra.PostId,
    ra.Title AS QuestionTitle,
    ra.ViewCount AS QuestionViews,
    ua.TotalQuestionsAsked,
    ua.TotalViews AS UserTotalViews,
    ua.UpvotedAnswers,
    ua.DownvotedAnswers,
    ua.AvgViewsPerQuestion,
    cr.CloseReason,
    cr.CloseCount
FROM 
    RankedPosts ra
JOIN 
    Users u ON ra.OwnerUserId = u.Id
JOIN 
    UserActivity ua ON u.Id = ua.UserId
LEFT JOIN 
    CloseReasons cr ON ra.PostId = cr.PostId
WHERE 
    ra.rn = 1  
ORDER BY 
    ra.ViewCount DESC, 
    ua.TotalQuestionsAsked DESC;
