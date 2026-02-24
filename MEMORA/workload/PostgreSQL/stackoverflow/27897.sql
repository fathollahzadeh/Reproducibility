
WITH PostTags AS (
    SELECT 
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT ph.PostId) AS TotalEdits,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5, 6) THEN 1 ELSE 0 END) AS TitleBodyTagEdits 
    FROM 
        Users u
    JOIN 
        PostHistory ph ON u.Id = ph.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TagStatistics AS (
    SELECT 
        pt.Tag,
        COUNT(pt.PostId) AS PostCount,
        COUNT(DISTINCT pt.PostId) FILTER (WHERE ph.PostHistoryTypeId = 10) AS ClosedPostCount, 
        AVG(u.Reputation) AS AvgUserReputation 
    FROM 
        PostTags pt
    LEFT JOIN 
        Posts p ON pt.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        Users u ON ph.UserId = u.Id
    GROUP BY 
        pt.Tag
),
FinalBenchmark AS (
    SELECT 
        ts.Tag,
        ts.PostCount,
        ts.ClosedPostCount,
        ts.AvgUserReputation,
        CASE 
            WHEN ts.PostCount > 0 THEN (CAST(ts.ClosedPostCount AS FLOAT) / ts.PostCount) * 100 
            ELSE 0 
        END AS ClosedPostPercentage
    FROM 
        TagStatistics ts
)
SELECT 
    fb.Tag,
    fb.PostCount,
    fb.ClosedPostCount,
    fb.AvgUserReputation,
    fb.ClosedPostPercentage
FROM 
    FinalBenchmark fb
ORDER BY 
    fb.ClosedPostPercentage DESC
LIMIT 10;
