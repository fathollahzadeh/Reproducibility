WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.ViewCount, 
        p.Score, 
        u.DisplayName AS OwnerDisplayName, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
), 
TopRankedPosts AS (
    SELECT 
        Id, 
        Title, 
        CreationDate, 
        ViewCount, 
        Score, 
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3
), 
PostStatistics AS (
    SELECT 
        trp.OwnerDisplayName, 
        COUNT(trp.Id) AS PostCount, 
        SUM(trp.Score) AS TotalScore, 
        AVG(trp.ViewCount) AS AvgViewCount
    FROM 
        TopRankedPosts trp
    GROUP BY 
        trp.OwnerDisplayName
)
SELECT 
    ps.OwnerDisplayName, 
    ps.PostCount, 
    ps.TotalScore, 
    ps.AvgViewCount, 
    u.Reputation, 
    COUNT(b.Id) AS BadgeCount
FROM 
    PostStatistics ps
JOIN 
    Users u ON ps.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    ps.OwnerDisplayName, ps.PostCount, ps.TotalScore, ps.AvgViewCount, u.Reputation
ORDER BY 
    ps.TotalScore DESC, ps.PostCount DESC;