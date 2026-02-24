
WITH TagStatistics AS (
    SELECT 
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 10 THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.Id, t.TagName
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),

PostHistorySummary AS (
    SELECT 
        ph.PostId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) 
    GROUP BY 
        ph.PostId, p.Title
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalAnswers,
    u.AcceptedAnswers,
    t.TagId,
    t.TagName,
    t.TotalPosts AS TagTotalPosts,
    t.Questions,
    t.Answers,
    t.ClosedPosts,
    p.Title AS PostTitle,
    ph.EditCount,
    ph.LastEditDate
FROM 
    UserActivity u
JOIN 
    TagStatistics t ON u.TotalPosts > 0
JOIN 
    Posts p ON p.OwnerUserId = u.UserId
JOIN 
    PostHistorySummary ph ON ph.PostId = p.Id
WHERE 
    t.TotalPosts > 0
    AND u.TotalAnswers > 0
ORDER BY 
    u.UserId, t.TagName, ph.LastEditDate DESC
LIMIT 100;
