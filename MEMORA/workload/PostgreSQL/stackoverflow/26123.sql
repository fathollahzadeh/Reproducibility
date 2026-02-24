
WITH TagStats AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(u.Reputation) AS AvgReputation,
        SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        t.TagName
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate,
        STRING_AGG(DISTINCT c.Text, '; ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS INTEGER) = crt.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        Comments c ON ph.PostId = c.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.AvgReputation,
    ts.TotalVotes,
    cp.LastClosedDate,
    cp.CloseReasons
FROM 
    TagStats ts
LEFT JOIN 
    ClosedPosts cp ON ts.PostCount > 0 AND cp.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.Tags LIKE '%' || ts.TagName || '%'
    )
ORDER BY 
    ts.PostCount DESC, 
    ts.AvgReputation DESC;
