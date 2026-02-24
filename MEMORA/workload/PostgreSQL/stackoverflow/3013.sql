WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS rn,
        ARRAY_LENGTH(string_to_array(p.Tags, ','), 1) AS TagCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(p.ViewCount) AS TotalViews,
        AVG(COALESCE(NULLIF(v.BountyAmount, 0), NULL)) AS AverageBounty
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Votes v ON u.Id = v.UserId AND v.VoteTypeId = 8 
    GROUP BY 
        u.Id, u.Reputation
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    us.Reputation,
    us.BadgeCount,
    us.TotalViews,
    us.AverageBounty,
    pc.CommentCount,
    rp.TagCount
FROM 
    RankedPosts rp
JOIN 
    PostComments pc ON rp.PostId = pc.PostId
JOIN 
    UserStatistics us ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    rp.rn <= 5
ORDER BY 
    rp.Score DESC, us.Reputation DESC;