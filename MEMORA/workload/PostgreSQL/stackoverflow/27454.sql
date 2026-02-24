
WITH TagStats AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Tags t
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        t.TagName
),
RecentPosts AS (
    SELECT 
        p.Id, 
        p.Title,
        p.CreationDate,
        p.Score,
        t.TagName
    FROM 
        Posts p
    JOIN 
        Tags t ON p.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
    ORDER BY 
        p.CreationDate DESC
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS Contributions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.DisplayName, u.Reputation
    ORDER BY 
        Contributions DESC
    LIMIT 10
),
PostHistoryStats AS (
    SELECT 
        ph.PostId, 
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT ph.Comment, '; ') AS Comments 
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)

SELECT 
    ts.TagName,
    ts.PostCount, 
    ts.QuestionCount, 
    ts.AnswerCount, 
    ts.AvgReputation,
    rp.Title AS RecentPostTitle,
    rp.CreationDate AS RecentPostDate,
    rp.Score AS RecentPostScore,
    tu.DisplayName AS TopUser,
    tu.Reputation AS TopUserReputation,
    phs.EditCount AS EditCount,
    phs.LastEdited AS LastEdited,
    phs.Comments AS RecentComments
FROM 
    TagStats ts
LEFT JOIN 
    RecentPosts rp ON ts.TagName = rp.TagName
LEFT JOIN 
    TopUsers tu ON ts.PostCount > 0
LEFT JOIN 
    PostHistoryStats phs ON phs.PostId = rp.Id 
WHERE 
    ts.PostCount > 5
ORDER BY 
    ts.PostCount DESC, 
    rp.CreationDate DESC, 
    tu.Contributions DESC
LIMIT 50;
