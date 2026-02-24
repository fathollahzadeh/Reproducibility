WITH TagStatistics AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        AVG(u.Reputation) AS AverageUserReputation,
        STRING_AGG(DISTINCT p.Title, '; ') AS PostTitles
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN Users u ON u.Id = p.OwnerUserId
    GROUP BY t.TagName
),
TopTags AS (
    SELECT 
        TagName, 
        PostCount, 
        AcceptedAnswers, 
        AverageUserReputation, 
        PostTitles,
        RANK() OVER (ORDER BY PostCount DESC) AS Rank
    FROM TagStatistics
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        ph.CreationDate AS ClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 
)
SELECT 
    tt.TagName,
    tt.PostCount,
    tt.AcceptedAnswers,
    tt.AverageUserReputation,
    closed.PostId,
    closed.Title,
    closed.ClosedDate
FROM TopTags tt
LEFT JOIN ClosedPosts closed ON tt.TagName LIKE '%' || closed.Title || '%'
WHERE tt.Rank <= 10
ORDER BY tt.PostCount DESC, tt.TagName;