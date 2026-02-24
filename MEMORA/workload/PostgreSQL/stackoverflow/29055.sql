
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViews,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived,
        SUM(CASE WHEN v.VoteTypeId IN (1, 2) THEN 1 ELSE 0 END) AS TotalVotes
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
CloseReasons AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        COUNT(*) AS CloseEventCount
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY ph.PostId, ph.Comment
),
CombinedStats AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AvgViews,
        ts.QuestionCount,
        ts.AnswerCount,
        ue.UserId,
        ue.DisplayName AS Author,
        ue.PostsCreated,
        ue.UpVotesReceived,
        ue.DownVotesReceived,
        ue.TotalVotes,
        cr.CloseEventCount
    FROM TagStats ts
    JOIN UserEngagement ue ON ue.PostsCreated > 0
    LEFT JOIN CloseReasons cr ON cr.PostId = (SELECT MIN(p.Id) FROM Posts p WHERE p.Tags LIKE CONCAT('%', ts.TagName, '%'))
    ORDER BY ts.PostCount DESC, ue.UpVotesReceived DESC
)
SELECT 
    TagName,
    Author,
    PostCount,
    AvgViews,
    QuestionCount,
    AnswerCount,
    PostsCreated,
    UpVotesReceived,
    DownVotesReceived,
    TotalVotes,
    COALESCE(CloseEventCount, 0) AS CloseEventCount
FROM CombinedStats
WHERE PostCount > 5  
LIMIT 100;
