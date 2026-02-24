WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(p.ViewCount) AS AverageViews,
        AVG(p.Score) AS AverageScore
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 0 
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        h.PostId,
        h.PostHistoryTypeId,
        COUNT(h.Id) AS HistoryCount,
        STRING_AGG(h.Comment, '; ') AS Comments
    FROM 
        PostHistory h
    GROUP BY 
        h.PostId, h.PostHistoryTypeId
),
FinalBenchmark AS (
    SELECT
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.AverageViews,
        ts.AverageScore,
        ua.TotalPosts,
        ua.QuestionsAsked,
        ua.AnswersGiven,
        ua.BadgesEarned,
        ph.HistoryCount,
        ph.Comments
    FROM 
        TagStatistics ts
    JOIN 
        UserActivity ua ON ua.TotalPosts > 0 
    LEFT JOIN 
        PostHistoryStats ph ON ph.PostId = ts.PostCount 
    ORDER BY 
        ts.PostCount DESC
)
SELECT 
    *
FROM 
    FinalBenchmark
WHERE 
    QuestionsAsked > 5 AND BadgesEarned > 2 
LIMIT 100;