
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.Reputation
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        v.PostId
)
SELECT 
    rp.Title AS PostTitle,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    COUNT(c.Id) AS CommentCount,
    COALESCE(rv.VoteCount, 0) AS TotalVotes,
    COALESCE(rv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(rv.DownVotes, 0) AS TotalDownVotes,
    RANK() OVER (ORDER BY COALESCE(rv.VoteCount, 0) DESC, rp.CreationDate DESC) AS PostRank,
    CASE 
        WHEN ur.BadgeCount >= 10 THEN 'Expert'
        WHEN ur.BadgeCount >= 5 THEN 'Intermediate'
        ELSE 'Beginner'
    END AS UserLevel
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON rp.Id = c.PostId
LEFT JOIN 
    RecentVotes rv ON rp.Id = rv.PostId
JOIN 
    UserReputation ur ON u.Id = ur.Id
WHERE 
    rp.PostRank = 1
GROUP BY 
    rp.Id, rp.Title, rp.CreationDate, u.Id, u.DisplayName, u.Reputation, ur.BadgeCount, rv.VoteCount, rv.UpVotes, rv.DownVotes
ORDER BY 
    TotalVotes DESC, rp.CreationDate DESC;
