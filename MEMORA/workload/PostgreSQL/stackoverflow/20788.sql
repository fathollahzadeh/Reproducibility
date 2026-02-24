WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate, 
        p.Score,
        p.OwnerUserId,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
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
),

PostTags AS (
    SELECT 
        p.Id AS PostId,
        t.TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    INNER JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '> <')) AS t(TagName) ON true
    GROUP BY 
        p.Id, t.TagName
),

TopPostStatistics AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.UserReputation,
        cp.LastClosedDate,
        STRING_AGG(pt.TagName, ', ') AS Tags
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
    LEFT JOIN 
        PostTags pt ON rp.PostId = pt.PostId
    WHERE 
        rp.RankScore <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Score, rp.UserReputation, cp.LastClosedDate
)

SELECT 
    tps.*,
    CASE
        WHEN tps.LastClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    CASE
        WHEN tps.UserReputation IS NULL THEN 'No Reputation'
        WHEN tps.UserReputation < 1000 THEN 'Low Reputation'
        ELSE 'High Reputation'
    END AS ReputationCategory
FROM 
    TopPostStatistics tps
WHERE 
    tps.Tags IS NOT NULL
ORDER BY 
    tps.Score DESC, tps.CreationDate ASC
LIMIT 20;