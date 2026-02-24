WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RN,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        AVG(ViewCount) AS AvgViewCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 5
),
PostHistoryTags AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, ',')) AS tag(tagName) ON TRUE
    JOIN 
        Tags t ON t.TagName = TRIM(tag.tagName)
    WHERE 
        ph.CreationDate >= cast('2024-10-01' as date) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId
)
SELECT 
    up.OwnerUserId,
    u.DisplayName AS UserDisplayName,
    up.TotalScore,
    up.PostCount,
    up.AvgViewCount,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.Score,
    COALESCE(pht.Tags, 'No Tags') AS PostTags,
    CASE 
        WHEN pp.Score >= 0 THEN 'Non-negative Score'
        ELSE 'Negative Score'
    END AS ScoreCategory
FROM 
    TopUsers up
JOIN 
    RankedPosts pp ON up.OwnerUserId = pp.PostId
LEFT JOIN 
    PostHistoryTags pht ON pp.PostId = pht.PostId
JOIN 
    Users u ON u.Id = up.OwnerUserId
WHERE 
    pp.RN = 1 
    AND up.PostCount > 10
ORDER BY 
    up.TotalScore DESC, 
    pp.ViewCount DESC
LIMIT 50;