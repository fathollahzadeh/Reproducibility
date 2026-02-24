WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        CASE 
            WHEN b.Class = 1 THEN 'Gold'
            WHEN b.Class = 2 THEN 'Silver'
            WHEN b.Class = 3 THEN 'Bronze'
            ELSE 'No Badge'
        END AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 1000
),
TopPosts AS (
    SELECT 
        rp.*,
        ur.DisplayName,
        ur.BadgeClass
    FROM 
        RankedPosts rp
    JOIN 
        UserReputation ur ON rp.OwnerUserId = ur.UserId
    WHERE 
        rp.PostRank = 1
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.DisplayName,
    tp.BadgeClass,
    COALESCE((SELECT STRING_AGG(t.TagName, ', ') 
               FROM Tags t 
               WHERE t.WikiPostId = tp.Id), 'No Tags') AS Tags,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.Id AND v.VoteTypeId = 2) AS UpVotes,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = tp.Id AND v.VoteTypeId = 3) AS DownVotes,
    CASE 
        WHEN tp.CommentCount > 0 THEN 'Has Comments' 
        ELSE 'No Comments' 
    END AS CommentStatus
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC
LIMIT 10;