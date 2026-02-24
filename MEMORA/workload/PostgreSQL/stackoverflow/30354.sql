WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
        AND p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(c.Id) AS CommentCount,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        u.DisplayName AS OwnerName,
        ua.TotalBounties,
        ua.CommentCount,
        ua.BadgeCount,
        RANK() OVER (ORDER BY rp.Score DESC) AS PostRank
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    JOIN 
        UserActivity ua ON u.Id = ua.UserId
    WHERE 
        rp.UserRank = 1
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.OwnerName,
    tp.TotalBounties,
    tp.CommentCount,
    tp.BadgeCount,
    CASE 
        WHEN tp.Score >= 100 THEN 'Hot Post'
        WHEN tp.Score BETWEEN 50 AND 99 THEN 'Trending Post'
        ELSE 'New Post'
    END AS PostCategory
FROM 
    TopPosts tp
WHERE 
    tp.PostRank <= 10
ORDER BY 
    tp.Score DESC;