WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COALESCE(SUM(rp.UpVoteCount - rp.DownVoteCount), 0) AS VoteBalance,
        COUNT(rp.PostId) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
)
SELECT 
    us.UserId,
    us.Reputation,
    us.VoteBalance,
    us.PostCount,
    CASE 
        WHEN us.PostCount > 10 THEN 'Active Contributor'
        WHEN us.Reputation > 1000 THEN 'Veteran User'
        ELSE 'New User'
    END AS UserCategory
FROM 
    UserStats us
WHERE 
    us.Reputation IS NOT NULL
ORDER BY 
    us.Reputation DESC
LIMIT 100;