
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '6 months' 
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score
), 
TopPosts AS (
    SELECT *
    FROM RankedPosts
    WHERE PostRank <= 10
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    us.DisplayName AS TopContributor,
    us.BadgeCount,
    us.TotalBounties
FROM 
    TopPosts tp
JOIN 
    UserStats us ON tp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = us.UserId)
ORDER BY 
    tp.Score DESC;
