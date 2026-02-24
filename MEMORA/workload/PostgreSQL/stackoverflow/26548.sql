WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        t.TagName
),
RecentActivity AS (
    SELECT 
        ph.PostId,
        COUNT(DISTINCT ph.UserId) AS EditorCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        ph.PostId
),
MergedData AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.AnswerCount,
        ts.QuestionCount,
        ts.AvgUserReputation,
        ra.EditorCount,
        ra.LastEditDate
    FROM 
        TagStatistics ts
    LEFT JOIN 
        RecentActivity ra ON ra.PostId = (
            SELECT p.Id 
            FROM Posts p 
            WHERE p.Tags LIKE '%' || ts.TagName || '%' 
            ORDER BY p.LastActivityDate DESC LIMIT 1
        )
)
SELECT 
    TagName, 
    PostCount, 
    QuestionCount, 
    AnswerCount, 
    AvgUserReputation,
    EditorCount,
    LastEditDate
FROM 
    MergedData
ORDER BY 
    PostCount DESC, 
    AvgUserReputation DESC;