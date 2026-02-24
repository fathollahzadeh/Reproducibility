
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (3, 4, 5) THEN 1 ELSE 0 END) AS WikiCount,
        AVG(u.Reputation) AS AverageReputation,
        MAX(p.CreationDate) AS LastPostDate,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%' 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
CloseReasons AS (
    SELECT 
        p.Id AS PostId,
        ph.CreationDate AS CloseDate,
        crt.Name AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INTEGER) = crt.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.WikiCount,
    ts.AverageReputation,
    ts.LastPostDate,
    ts.TopUsers,
    cr.CloseReason,
    cr.CloseDate
FROM 
    TagStatistics ts
LEFT JOIN 
    CloseReasons cr ON ts.PostCount > 0
ORDER BY 
    ts.PostCount DESC,
    ts.AverageReputation DESC
LIMIT 10;
