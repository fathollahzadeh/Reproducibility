
WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        DisplayName,
        0 AS Level
    FROM 
        Users
    WHERE 
        Reputation > 1000

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.CreationDate,
        u.DisplayName,
        ur.Level + 1 AS Level
    FROM 
        Users u
    JOIN 
        UserReputation ur ON u.Id = ur.Id
    WHERE 
        u.Reputation > ur.Reputation
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(b.BadgeCount, 0) AS TotalBadges,
    COALESCE(p.PostCount, 0) AS TotalPosts,
    COALESCE(pc.CommentCount, 0) AS TotalComments,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.CreationDate DESC) AS UserRank,
    STRING_AGG(tags.TagName, ', ') AS Tags,
    MAX(v.BountyAmount) AS MaxBounty
FROM 
    Users u
LEFT JOIN (
    SELECT 
        UserId, 
        COUNT(*) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
) b ON u.Id = b.UserId
LEFT JOIN (
    SELECT 
        OwnerUserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    WHERE 
        CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
    GROUP BY 
        OwnerUserId
) p ON u.Id = p.OwnerUserId
LEFT JOIN (
    SELECT 
        UserId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        UserId
) pc ON u.Id = pc.UserId
LEFT JOIN (
    SELECT 
        pt.Id, 
        t.TagName 
    FROM 
        Posts pt
    CROSS JOIN 
        UNNEST(STRING_TO_ARRAY(pt.Tags, '><')) AS t(TagName)
) tags ON tags.Id = (
    SELECT 
        p.Id
    FROM 
        Posts p
    WHERE 
        p.OwnerUserId = u.Id
    LIMIT 1
)
LEFT JOIN (
    SELECT 
        PostId, 
        MAX(BountyAmount) AS BountyAmount
    FROM 
        Votes
    WHERE 
        VoteTypeId = 8
    GROUP BY 
        PostId
) v ON v.PostId = (
    SELECT 
        Id 
    FROM 
        Posts 
    WHERE 
        OwnerUserId = u.Id
    ORDER BY 
        CreationDate DESC
    LIMIT 1
)
WHERE 
    (u.LastAccessDate >= DATE '2024-10-01' - INTERVAL '30 days' OR u.Reputation > 2000)
GROUP BY 
    u.Id, u.DisplayName, b.BadgeCount, p.PostCount, pc.CommentCount
HAVING 
    COUNT(DISTINCT v.PostId) > 0
ORDER BY 
    UserRank, u.Reputation DESC;
