WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '6 months'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        MAX(u.CreationDate) AS AccountCreation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.RankScore,
    us.DisplayName AS Author,
    us.TotalUpVotes,
    us.TotalDownVotes,
    us.BadgeCount,
    CASE 
        WHEN rp.CommentCount > 5 THEN 'Highly Discussed'
        WHEN rp.CommentCount BETWEEN 1 AND 5 THEN 'Moderately Discussed'
        ELSE 'Not Discussed'
    END AS DiscussionLevel
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserStats us ON u.Id = us.UserId
WHERE 
    rp.RankScore <= 10
  AND 
    p.PostTypeId = 1
ORDER BY 
    rp.Score DESC, us.BadgeCount DESC
LIMIT 50;