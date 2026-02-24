WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ARRAY_LENGTH(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '>'), 1) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.DisplayName, u.Reputation
    HAVING 
        COUNT(p.Id) > 5 
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.TagCount,
    ts.TagName,
    ts.PostCount,
    tu.DisplayName AS TopUser,
    tu.TotalPosts,
    tu.TotalScore
FROM 
    RankedPosts rp
JOIN 
    TagStatistics ts ON rp.Tags LIKE '%' || ts.TagName || '%'
JOIN 
    TopUsers tu ON rp.OwnerDisplayName = tu.DisplayName
WHERE 
    rp.PostRank = 1 
ORDER BY 
    rp.CreationDate DESC, 
    tu.TotalScore DESC;