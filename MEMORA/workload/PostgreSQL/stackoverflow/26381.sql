
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserEngagement AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,  
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived  
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON c.UserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPostReasons AS (
    SELECT 
        ph.PostHistoryTypeId,
        COUNT(DISTINCT ph.PostId) AS ClosedPostCount,
        STRING_AGG(p.Title, '; ') AS ClosedPostTitles,
        STRING_AGG(u.DisplayName, '; ') AS UserDisplayNames
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostHistoryTypeId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.TotalViews,
    ts.AverageScore,
    ue.DisplayName AS TopUser,
    ue.Reputation AS TopUserReputation,
    ue.TotalPosts,
    ue.TotalComments,
    ue.UpVotesReceived,
    ue.DownVotesReceived,
    cr.ClosedPostCount,
    cr.ClosedPostTitles,
    cr.UserDisplayNames
FROM 
    TagStatistics ts
JOIN 
    UserEngagement ue ON ue.TotalPosts = (
        SELECT MAX(TotalPosts) FROM UserEngagement
    )
LEFT JOIN 
    ClosedPostReasons cr ON cr.PostHistoryTypeId = 10  
ORDER BY 
    ts.PostCount DESC
FETCH FIRST 10 ROWS ONLY;
