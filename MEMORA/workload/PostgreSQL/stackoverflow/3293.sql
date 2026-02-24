WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.Score > 0 
        AND p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserReputations AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN SUM(b.Class) >= 5 THEN 'Experienced'
            WHEN SUM(b.Class) BETWEEN 1 AND 4 THEN 'Moderate'
            ELSE 'Newbie'
        END AS UserType
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName
)
SELECT 
    up.DisplayName,
    up.Reputation,
    up.UserType,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.CommentCount
FROM 
    RankedPosts rp
INNER JOIN 
    UserReputations up ON rp.OwnerUserId = up.UserId
WHERE 
    rp.RankByUser <= 5
    AND (rp.CommentCount > 10 OR up.Reputation > 5000)
ORDER BY 
    up.Reputation DESC, 
    rp.CreationDate DESC
LIMIT 100;