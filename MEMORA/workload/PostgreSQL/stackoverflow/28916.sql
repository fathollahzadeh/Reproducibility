WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBountyAwarded
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PopularTagPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Tags,
        COUNT(c.Id) AS CommentCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    WHERE 
        rp.TagRank <= 5 
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.OwnerUserId, rp.Tags
),
TopActiveUsers AS (
    SELECT 
        au.UserId,
        au.DisplayName,
        au.BadgeCount,
        au.TotalBountyAwarded,
        ROW_NUMBER() OVER (ORDER BY au.BadgeCount DESC, au.TotalBountyAwarded DESC) AS UserRank
    FROM 
        ActiveUsers au
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Tags,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    p.CommentCount,
    a.DisplayName AS TopActiveUser,
    a.BadgeCount,
    a.TotalBountyAwarded
FROM 
    PopularTagPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    (SELECT * FROM TopActiveUsers WHERE UserRank <= 10) a ON a.UserId = u.Id 
ORDER BY 
    p.CommentCount DESC, 
    p.CreationDate DESC;