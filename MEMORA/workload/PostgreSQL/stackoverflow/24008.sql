
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS RankByType
    FROM 
        Posts p
    WHERE 
        p.ViewCount IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
),
PostTagData AS (
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        LATERAL (SELECT UNNEST(string_to_array(SUBSTRING(p.Tags FROM 2 FOR LENGTH(p.Tags) - 2), '><')) AS tag) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        p.Id
)
SELECT 
    p.PostId,
    p.Title,
    CONCAT(u.DisplayName, ' (Reputation: ', u.Reputation + COALESCE(u.TotalBounties, 0), ')') AS UserProfile,
    p.CreationDate,
    COALESCE(pt.Tags, 'No Tags') AS AssociatedTags,
    CASE 
        WHEN p.RankByType = 1 THEN 'Latest'
        WHEN p.RankByType <= 3 THEN 'Popular'
        ELSE 'Other'
    END AS PostRank
FROM 
    RankedPosts p
LEFT JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostTagData pt ON p.PostId = pt.PostId
WHERE 
    p.RankByType <= 10 
    AND (u.Reputation > 1000 OR u.Reputation IS NULL) 
ORDER BY 
    p.CreationDate DESC, 
    u.Reputation DESC NULLS LAST
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
