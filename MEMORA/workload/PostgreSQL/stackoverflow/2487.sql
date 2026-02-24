
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND (p.PostTypeId = 1 OR p.PostTypeId = 2)
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN u.Reputation < 100 THEN 'Low Reputation'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM 
        Users u
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    ur.DisplayName,
    ur.ReputationCategory,
    rp.CommentCount,
    COALESCE(th.Tags, 'No Tags') AS Tags
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
LEFT JOIN 
    (SELECT 
        p.Id,
        STRING_AGG(t.TagName, ', ') AS Tags
     FROM 
        Posts p
     JOIN 
        UNNEST(STRING_TO_ARRAY(p.Tags, ',')) AS TagArray ON TRUE
     JOIN 
        Tags t ON t.TagName = TagArray
     GROUP BY 
        p.Id) th ON rp.PostId = th.Id
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.CommentCount DESC,
    ur.Reputation DESC;
