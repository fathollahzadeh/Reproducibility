WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 10
),
RecentUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        RANK() OVER (ORDER BY u.CreationDate DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.LastAccessDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
)
SELECT 
    ru.DisplayName,
    COUNT(DISTINCT rp.Id) AS TotalQuestions,
    COALESCE(SUM(rp.Score), 0) AS TotalScore,
    SUM(rp.ViewCount) AS TotalViews,
    CASE 
        WHEN ru.Reputation > 1000 THEN 'Experienced User'
        ELSE 'New User'
    END AS UserCategory,
    STRING_AGG(DISTINCT t.TagName, ', ') AS TagsUsed
FROM 
    RecentUsers ru
LEFT JOIN 
    Posts p ON ru.UserId = p.OwnerUserId AND p.PostTypeId = 1
LEFT JOIN 
    LATERAL (
        SELECT 
            UNNEST(string_to_array(p.Tags, '<>')) AS TagName
    ) t ON true
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.Id
GROUP BY 
    ru.DisplayName, ru.Reputation
HAVING 
    COUNT(DISTINCT rp.Id) > 5 OR SUM(rp.Score) > 50
ORDER BY 
    TotalScore DESC, UserCategory;