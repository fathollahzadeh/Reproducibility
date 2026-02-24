WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
TagCloseReasons AS (
    SELECT 
        p.Tags,
        ph.Comment AS CloseReason,
        ph.CreationDate,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS Moderators
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId IN (10, 11) 
    JOIN 
        Users u ON ph.UserId = u.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Tags, ph.Comment, ph.CreationDate
),
FinalBenchmarkReport AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.QuestionCount,
        ts.AnswerCount,
        ts.AvgUserReputation,
        ts.TopUsers,
        tcr.CloseReason,
        tcr.CreationDate
    FROM 
        TagStatistics ts
    LEFT JOIN 
        TagCloseReasons tcr ON ts.TagName = tcr.Tags
)

SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AvgUserReputation,
    TopUsers,
    CloseReason,
    CreationDate
FROM 
    FinalBenchmarkReport
ORDER BY 
    PostCount DESC, QuestionCount DESC
LIMIT 10;