
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        t.TagName
),
ClosedPosts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(ph.Id) AS CloseHistoryCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON ph.PostId = p.Id AND ph.PostHistoryTypeId = 10  
    GROUP BY 
        p.Id
    HAVING 
        COUNT(ph.Id) > 0
),
TagCloseStats AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        ts.PopularPostCount,
        ts.AvgUserReputation,
        COALESCE(cp.CloseHistoryCount, 0) AS CloseCount
    FROM 
        TagStats ts
    LEFT JOIN 
        ClosedPosts cp ON ts.TagName IN (
            SELECT unnest(string_to_array(p.Tags, '><')) 
            FROM Posts p 
            WHERE p.PostTypeId = 1
        )
)
SELECT 
    TagName,
    PostCount,
    PopularPostCount,
    AvgUserReputation,
    CloseCount
FROM 
    TagCloseStats
ORDER BY 
    PostCount DESC, PopularPostCount DESC;
