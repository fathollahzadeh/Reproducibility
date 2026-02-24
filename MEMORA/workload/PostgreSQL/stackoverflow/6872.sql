WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    INNER JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 5 
),
TopUsers AS (
    SELECT 
        R.OwnerDisplayName,
        COUNT(R.PostId) AS TotalPosts,
        SUM(R.ViewCount) AS TotalViews,
        SUM(R.Score) AS TotalScore
    FROM 
        RankedPosts R
    WHERE 
        R.PostRank <= 5
    GROUP BY 
        R.OwnerDisplayName
),
TopTags AS (
    SELECT 
        tag.TagName,
        COUNT(p.Id) AS TagUsage
    FROM 
        Tags tag
    INNER JOIN 
        Posts p ON p.Tags LIKE CONCAT('%<', tag.TagName, '>%')
    GROUP BY 
        tag.TagName
    ORDER BY 
        TagUsage DESC
    LIMIT 10
)
SELECT 
    U.DisplayName AS TopUser,
    U.Reputation,
    T.TotalPosts,
    T.TotalViews,
    T.TotalScore,
    Tag.TagName AS FrequentTag,
    Tag.TagUsage
FROM 
    TopUsers T
INNER JOIN 
    Users U ON T.OwnerDisplayName = U.DisplayName
CROSS JOIN 
    TopTags Tag
ORDER BY 
    T.TotalPosts DESC, 
    T.TotalViews DESC;
