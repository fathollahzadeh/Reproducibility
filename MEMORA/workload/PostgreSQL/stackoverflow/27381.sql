WITH TagAnalytics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(u.Reputation) AS AverageReputation,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS UserNames
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.TagName
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pr.Name, ', ') AS CloseReasons,
        COUNT(DISTINCT ph.Id) AS ClosureCount
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes pr ON ph.Comment::INT = pr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        ph.PostId
)

SELECT 
    ta.TagName,
    ta.PostCount,
    ta.AverageReputation,
    ta.TotalAnswers,
    ta.TotalQuestions,
    cp.CloseReasons,
    cp.ClosureCount,
    ta.UserNames
FROM 
    TagAnalytics ta
LEFT JOIN 
    ClosedPosts cp ON ta.PostCount = cp.PostId
ORDER BY 
    ta.PostCount DESC,
    ta.AverageReputation DESC;