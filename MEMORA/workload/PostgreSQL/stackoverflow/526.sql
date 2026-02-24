
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank,
        SUM(v.BountyAmount) AS TotalBounty,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.UpVotes) AS TotalUpVotes,
        SUM(u.DownVotes) AS TotalDownVotes,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    us.DisplayName AS UserDisplayName,
    us.TotalUpVotes,
    us.TotalDownVotes,
    rp.TotalBounty,
    CASE 
        WHEN rp.UserPostRank <= 5 THEN 'Top Posts'
        ELSE 'Regular Posts'
    END AS PostRankCategory
FROM 
    RankedPosts rp
INNER JOIN 
    UserStats us ON rp.OwnerUserId = us.UserId
WHERE 
    rp.CommentCount > 5 
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC
OFFSET 10 ROWS FETCH NEXT 20 ROWS ONLY;
