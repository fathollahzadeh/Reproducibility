WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Score, p.PostTypeId
)
SELECT 
    r.PostId,
    r.Title,
    r.OwnerDisplayName,
    r.TotalComments,
    r.TotalVotes,
    r.PostRank,
    pt.Name AS PostType,
    COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM 
    RankedPosts r
JOIN 
    PostTypes pt ON r.PostRank = 1  
LEFT JOIN 
    Badges b ON b.UserId = (SELECT u.Id FROM Users u WHERE u.DisplayName = r.OwnerDisplayName LIMIT 1)
WHERE 
    r.TotalVotes > 5 AND r.TotalComments > 3
GROUP BY 
    r.PostId, r.Title, r.OwnerDisplayName, r.TotalComments, r.TotalVotes, r.PostRank, pt.Name
ORDER BY 
    r.PostRank, r.TotalVotes DESC;