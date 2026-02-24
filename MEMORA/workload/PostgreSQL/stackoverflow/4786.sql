WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
),
ClosedQuestions AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserDisplayName,
        p.Title
    FROM 
        PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
        AND ph.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN Posts pt ON pt.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
)
SELECT 
    ua.DisplayName AS UserName,
    ua.TotalPosts,
    ua.TotalQuestions,
    ua.TotalAnswers,
    ua.AcceptedAnswers,
    COALESCE(ua.AverageBounty, 0) AS AverageBounty,
    cq.Title AS ClosedQuestionTitle,
    cq.CreationDate AS ClosedDate,
    cq.UserDisplayName AS ClosedBy,
    tt.TagName AS PopularTag
FROM 
    UserActivity ua
LEFT JOIN ClosedQuestions cq ON ua.TotalQuestions > 0
LEFT JOIN TopTags tt ON ua.TotalPosts > 0
WHERE 
    ua.TotalPosts > 10
ORDER BY 
    ua.TotalPosts DESC, ua.TotalQuestions DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;