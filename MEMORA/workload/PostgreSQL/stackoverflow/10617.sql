WITH UserLatestPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
)
SELECT 
    ul.UserId,
    ul.DisplayName,
    ul.Reputation,
    ul.PostId,
    ul.Title,
    ul.PostCreationDate
FROM 
    UserLatestPosts ul
WHERE 
    ul.rn = 1
ORDER BY 
    ul.Reputation DESC
LIMIT 100;