
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        LATERAL (SELECT unnest(string_to_array(p.Tags, '>')) AS tagName) AS tagName ON true
    LEFT JOIN 
        Tags t ON t.TagName = tagName.tagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId, u.DisplayName
),
TopUsers AS (
    SELECT 
        OwnerUserId, 
        COUNT(*) AS PostCount,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts 
    WHERE 
        PostRank <= 5 
    GROUP BY 
        OwnerUserId
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    ARRAY_AGG(rp.Title) AS TopPostTitles,
    ARRAY_AGG(rp.Score) AS TopPostScores
FROM 
    TopUsers tu
JOIN 
    Users u ON u.Id = tu.OwnerUserId
JOIN 
    RankedPosts rp ON rp.OwnerUserId = u.Id
GROUP BY 
    u.Id, u.DisplayName, tu.PostCount, tu.TotalScore, tu.TotalViews
ORDER BY 
    tu.TotalScore DESC;
