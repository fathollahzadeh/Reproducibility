WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.LastActivityDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
MostActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 5  
),
HighestRankedTags AS (
    SELECT 
        t.TagName,
        COUNT(rp.PostId) AS PostCount,
        AVG(rp.ViewCount) AS AvgViews,
        AVG(rp.Score) AS AvgScore
    FROM 
        RankedPosts rp
    JOIN 
        Tags t ON rp.Tags LIKE '%' || t.TagName || '%'
    WHERE 
        rp.TagRank = 1  
    GROUP BY 
        t.TagName
)
SELECT 
    au.DisplayName AS ActiveUser,
    au.PostCount,
    au.TotalBounties,
    hrt.TagName,
    hrt.PostCount AS TagPostCount,
    hrt.AvgViews,
    hrt.AvgScore
FROM 
    MostActiveUsers au
JOIN 
    HighestRankedTags hrt ON au.PostCount > 10  
ORDER BY 
    au.PostCount DESC, 
    hrt.PostCount DESC
LIMIT 10;