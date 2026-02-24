WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS tag ON tag IS NOT NULL
    LEFT JOIN 
        Tags t ON t.TagName = tag
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score
),
ActiveUserPosts AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        pm.PostId,
        pm.Title,
        pm.ViewCount,
        pm.CommentCount,
        pm.Score,
        pm.Tags
    FROM 
        UserActivity ua
    JOIN 
        PostMetrics pm ON pm.PostId IN (
            SELECT p.Id 
            FROM Posts p 
            WHERE p.OwnerUserId = ua.UserId
        )
)
SELECT 
    a.DisplayName,
    COUNT(a.PostId) AS NumberOfPosts,
    SUM(a.ViewCount) AS TotalViews,
    AVG(a.Score) AS AvgScore,
    STRING_AGG(a.Tags, ', ') AS AssociatedTags
FROM 
    ActiveUserPosts a
GROUP BY 
    a.DisplayName
ORDER BY 
    NumberOfPosts DESC
LIMIT 10;