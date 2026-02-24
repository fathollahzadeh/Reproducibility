
WITH TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation,
        STRING_AGG(DISTINCT u.DisplayName, ', ') AS TopUsers
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    GROUP BY t.TagName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        PHT.Name AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS rn
    FROM PostHistory ph
    JOIN PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
    WHERE PHT.Name IN ('Post Closed', 'Post Reopened', 'Edit Body')
),
ClosedPosts AS (
    SELECT 
        rp.PostId,
        rp.CreationDate,
        rp.HistoryType
    FROM RecentPostHistory rp
    JOIN RecentPostHistory rp2 ON rp.PostId = rp2.PostId
    WHERE rp.rn = 1 AND rp2.rn = 2 AND rp2.HistoryType = 'Post Reopened'
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.AvgReputation,
    ts.TopUsers,
    COUNT(DISTINCT cp.PostId) AS ReopenedPostCount
FROM TagStatistics ts
LEFT JOIN ClosedPosts cp ON cp.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE CONCAT('%<', ts.TagName, '>%'))
GROUP BY 
    ts.TagName, 
    ts.PostCount, 
    ts.QuestionCount, 
    ts.AnswerCount, 
    ts.AvgReputation, 
    ts.TopUsers
ORDER BY 
    ts.PostCount DESC, 
    ts.QuestionCount DESC;
