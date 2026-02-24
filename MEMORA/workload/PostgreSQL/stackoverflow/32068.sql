
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Score,
        u.DisplayName,
        us.TotalUpvotes - us.TotalDownvotes AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY tp.Score DESC) AS EngagementRank
    FROM 
        TopPosts tp
    JOIN 
        Posts p ON tp.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        UserStatistics us ON u.Id = us.UserId
)
SELECT 
    pe.PostId,
    pe.Title,
    pe.Score,
    pe.NetVotes,
    pe.EngagementRank,
    CASE 
        WHEN pe.NetVotes > 100 THEN 'High Engagement'
        WHEN pe.NetVotes BETWEEN 50 AND 100 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementCategory
FROM 
    PostEngagement pe
WHERE 
    pe.NetVotes IS NOT NULL
ORDER BY 
    pe.EngagementRank;
