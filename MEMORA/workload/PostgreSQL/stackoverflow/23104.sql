
WITH CTE_UserActivity AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount,
        AVG(v.BountyAmount) AS AvgBountyAmount,
        MIN(v.CreationDate) AS FirstVoteDate,
        MAX(v.CreationDate) AS LastVoteDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id
    GROUP BY u.Id
),
CTE_PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.UserId) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount,
        COUNT(DISTINCT ph.UserId) FILTER (WHERE ph.PostHistoryTypeId = 11) AS ReopenCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 YEAR'
    GROUP BY p.Id, p.Title, p.CreationDate
),
CTE_TagUsage AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN Comments c ON c.PostId = p.Id
    GROUP BY t.TagName
),
CTE_ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ua.PostCount, 0) AS TotalPosts,
        COALESCE(ua.AnswerCount, 0) AS TotalAnswers,
        COALESCE(ua.PositiveScoreCount, 0) AS PositiveScores,
        COALESCE(ua.AvgBountyAmount, 0) AS AvgBounty,
        CASE 
            WHEN ua.FirstVoteDate IS NOT NULL AND ua.LastVoteDate IS NOT NULL THEN 
                DATE_PART('day', ua.LastVoteDate - ua.FirstVoteDate) 
            ELSE 
                NULL 
        END AS VoteSpanDays
    FROM Users u
    LEFT JOIN CTE_UserActivity ua ON u.Id = ua.UserId
),
CTE_FinalOutput AS (
    SELECT 
        u.UserId,
        u.DisplayName,
        p.PostId,
        p.Title,
        p.CommentCount,
        p.CloseCount,
        p.ReopenCount,
        t.TagName,
        t.PostCount AS TagPostCount,
        u.TotalPosts,
        u.TotalAnswers,
        u.PositiveScores,
        u.AvgBounty,
        u.VoteSpanDays
    FROM CTE_ActiveUsers u
    JOIN CTE_PostStats p ON u.UserId = p.RowNum
    JOIN CTE_TagUsage t ON p.Title ILIKE CONCAT('%', t.TagName, '%') 
)

SELECT 
    UserId,
    DisplayName,
    PostId,
    Title,
    CommentCount,
    CloseCount,
    ReopenCount,
    TagName,
    TagPostCount,
    TotalPosts,
    TotalAnswers,
    PositiveScores,
    AvgBounty,
    VoteSpanDays
FROM CTE_FinalOutput
WHERE 
    (VoteSpanDays IS NOT NULL AND VoteSpanDays > 365) 
    OR (TotalPosts > 10 AND AvgBounty > 5)
ORDER BY Title, UserId;
