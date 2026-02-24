
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(EXTRACT(EPOCH FROM COALESCE(p.LastActivityDate, TIMESTAMP '2024-10-01 12:34:56') - p.CreationDate)) AS AvgResponseTime
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        t.TagName
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvotesReceived,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
CloseReasonStats AS (
    SELECT 
        C.Name AS CloseReason,
        COUNT(ph.Id) AS CloseCount,
        AVG(EXTRACT(EPOCH FROM ph.CreationDate - p.CreationDate)) AS AvgClosureTime
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON p.Id = ph.PostId
    JOIN 
        CloseReasonTypes C ON ph.Comment::integer = C.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        C.Name
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.TotalUpvotes,
    ts.TotalDownvotes,
    ts.AvgResponseTime,
    us.DisplayName as TopUser,
    us.TotalPosts,
    us.Questions,
    us.Answers,
    us.UpvotesReceived,
    crs.CloseReason,
    crs.CloseCount,
    crs.AvgClosureTime
FROM 
    TagStats ts
JOIN 
    UserStats us ON us.TotalPosts = (
        SELECT MAX(TotalPosts) FROM UserStats
    )
JOIN 
    CloseReasonStats crs ON crs.CloseCount = (
        SELECT MAX(CloseCount) FROM CloseReasonStats
    )
ORDER BY 
    ts.PostCount DESC;
