
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.OwnerUserId
), FilteredUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        CASE 
            WHEN u.Reputation > 1000 THEN 'High Contributor'
            WHEN u.Reputation > 100 THEN 'Moderate Contributor'
            ELSE 'New Contributor'
        END AS ContributorLevel
    FROM 
        Users u
    WHERE 
        u.CreationDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '6 months'
)

SELECT 
    fu.UserId,
    fu.DisplayName,
    fu.ContributorLevel,
    COUNT(rp.Id) AS PostsCount,
    SUM(rp.Score) AS TotalScore,
    AVG(rp.ViewCount) AS AvgViews,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes
FROM 
    FilteredUsers fu
JOIN 
    Posts p ON p.OwnerUserId = fu.UserId
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
LEFT JOIN 
    RankedPosts rp ON p.Id = rp.Id
WHERE 
    rp.ScoreRank <= 10 OR rp.CommentCount > 5
GROUP BY 
    fu.UserId, fu.DisplayName, fu.ContributorLevel
HAVING 
    COUNT(rp.Id) > 0
ORDER BY 
    TotalScore DESC, PostsCount DESC;
