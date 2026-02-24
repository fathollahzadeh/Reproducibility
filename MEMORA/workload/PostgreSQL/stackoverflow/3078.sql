WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes IS NULL THEN 0 
            ELSE rp.UpVotes 
        END AS SafeUpVotes,
        CASE 
            WHEN rp.DownVotes IS NULL THEN 0 
            ELSE rp.DownVotes 
        END AS SafeDownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
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
        u.Reputation > 1000
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.SafeUpVotes,
    fp.SafeDownVotes,
    ur.DisplayName AS OwnerDisplayName,
    ur.Reputation AS OwnerReputation,
    CASE 
        WHEN fp.SafeUpVotes > fp.SafeDownVotes THEN 'Positively Received' 
        WHEN fp.SafeUpVotes < fp.SafeDownVotes THEN 'Negatively Received' 
        ELSE 'Neutral' 
    END AS ReceptionStatus
FROM 
    FilteredPosts fp
JOIN 
    Posts p ON fp.PostId = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
JOIN 
    UserReputation ur ON u.Id = ur.UserId
WHERE 
    p.CreationDate > (cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days')
ORDER BY 
    fp.CommentCount DESC, fp.CreationDate DESC;