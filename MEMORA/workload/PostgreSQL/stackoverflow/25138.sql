WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
),
TopUserPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        rp.OwnerDisplayName,
        rp.CreationDate,
        STRING_AGG(t.TagName, ', ') AS TagList
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Tags t ON POSITION(t.TagName IN rp.Tags) > 0 
    WHERE 
        rp.Rank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.ViewCount, rp.OwnerDisplayName, rp.CreationDate
),
UserStatistics AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId IN (1, 2) 
    GROUP BY 
        u.DisplayName
)
SELECT 
    ups.OwnerDisplayName,
    ups.Title,
    ups.ViewCount,
    ups.TagList,
    us.TotalPosts,
    us.TotalAnswers,
    us.PopularPosts
FROM 
    TopUserPosts ups
JOIN 
    UserStatistics us ON ups.OwnerDisplayName = us.DisplayName
ORDER BY 
    ups.ViewCount DESC, us.TotalPosts DESC
LIMIT 10;