
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(v.Id) AS VoteCount
    FROM 
        Users u
    JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(v.Id) > 10
),
RecentTagUsage AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    WHERE 
        p.CreationDate > TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 5
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 10
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    pu.DisplayName AS PopularUser,
    pu.Reputation AS UserReputation,
    rt.TagName AS RecentTag,
    cp.LastClosedDate
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularUsers pu ON rp.PostId IN (SELECT PostId FROM Votes WHERE UserId = pu.UserId)
LEFT JOIN 
    RecentTagUsage rt ON EXISTS (SELECT 1 FROM Posts p WHERE p.Id = rp.PostId AND p.Tags LIKE CONCAT('%', rt.TagName, '%'))
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
WHERE 
    rp.PostRank <= 5
AND 
    (cp.LastClosedDate IS NULL OR cp.LastClosedDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months')
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
