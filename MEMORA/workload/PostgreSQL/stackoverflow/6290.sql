
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.OwnerUserId, p.CreationDate
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        Score, 
        CommentCount, 
        UpvoteCount, 
        DownvoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS TotalBadges,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    up.DisplayName,
    up.TotalBadges,
    up.TotalScore,
    tp.Title,
    tp.Score AS PostScore,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount
FROM 
    UserReputation up
JOIN 
    TopPosts tp ON up.UserId = tp.PostId
ORDER BY 
    up.TotalScore DESC, 
    tp.Score DESC
LIMIT 50;
