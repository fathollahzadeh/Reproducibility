
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<%s>', t.TagName, '%</%s>%') 
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    GROUP BY 
        t.TagName
),
RecentEdits AS (
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.Comment,
        CASE 
            WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 'Edited'
            WHEN ph.PostHistoryTypeId IN (10, 11) THEN 'Closed/Reopened'
            ELSE 'Other'
        END AS EditType
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgUserReputation,
    COUNT(re.PostId) AS RecentEditCount
FROM 
    TagStats ts
LEFT JOIN 
    RecentEdits re ON re.PostId IN (
        SELECT Id FROM Posts WHERE Tags LIKE CONCAT('%<%s>', ts.TagName, '%</%s>%')
    )
GROUP BY 
    ts.TagName, ts.PostCount, ts.QuestionCount, ts.AnswerCount, ts.AvgUserReputation
ORDER BY 
    ts.PostCount DESC
LIMIT 10;
