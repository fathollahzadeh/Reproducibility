
WITH RecentPostData AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(pt.Name, 'Unknown') AS PostType,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate > (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '30 days')
    GROUP BY 
        p.Id, p.OwnerUserId, pt.Name, p.Title, p.CreationDate
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
)
SELECT 
    up.UserId,
    up.DisplayName,
    up.Reputation,
    COUNT(rpd.PostId) AS RecentPostCount,
    SUM(rpd.UpVotes) AS TotalUpVotes,
    SUM(rpd.DownVotes) AS TotalDownVotes,
    SUM(rpd.CommentCount) AS TotalComments
FROM 
    UserReputation up
LEFT JOIN 
    RecentPostData rpd ON up.UserId = rpd.OwnerUserId
WHERE 
    up.UserRank <= 10
GROUP BY 
    up.UserId, up.DisplayName, up.Reputation
ORDER BY 
    up.Reputation DESC;
