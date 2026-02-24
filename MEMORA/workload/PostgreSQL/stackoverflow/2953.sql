
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER(PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.Score > 0
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(Tags, ',')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
    GROUP BY 
        unnest(string_to_array(Tags, ','))
    HAVING 
        COUNT(*) > 5
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.TotalScore,
    tu.TotalViews,
    RANK() OVER (ORDER BY tu.TotalScore DESC) AS UserRank,
    pt.TagName,
    pt.TagCount
FROM 
    TopUsers tu
LEFT JOIN 
    PopularTags pt ON pt.TagName IN (
        SELECT 
            unnest(string_to_array(Tags, ','))
        FROM 
            Posts
        WHERE 
            OwnerUserId = tu.UserId
    )
WHERE 
    EXISTS (
        SELECT 
            1 
        FROM 
            Votes v 
        WHERE 
            v.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = tu.UserId) 
            AND v.VoteTypeId = 2
    )
ORDER BY 
    tu.TotalScore DESC, tu.PostCount DESC;
