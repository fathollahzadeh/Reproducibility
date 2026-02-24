WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) AND
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.Name, 'No Badge') AS BadgeName,
        COALESCE(b.Class, 3) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId AND b.Class = 1
)
SELECT 
    p.PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation,
    COALESCE(up.UpVotes, 0) AS UpVotes,
    COALESCE(dn.DownVotes, 0) AS DownVotes,
    CASE 
        WHEN PostRank = 1 THEN 'Highest Scored Post'
        ELSE 'Other Posts'
    END AS PostCategory,
    CASE 
        WHEN p.CreationDate < cast('2024-10-01' as date) - INTERVAL '6 months' THEN 'Older Post'
        ELSE 'Recent Post'
    END AS PostAge
FROM 
    RankedPosts p
JOIN 
    UserDetails u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    PostVotes up ON p.PostId = up.PostId
LEFT JOIN 
    PostVotes dn ON p.PostId = dn.PostId
WHERE 
    p.PostRank <= 5
ORDER BY 
    p.Score DESC, u.Reputation DESC;