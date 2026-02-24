WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PostVotes AS (
    SELECT 
        pv.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes pv
    JOIN 
        VoteTypes vt ON pv.VoteTypeId = vt.Id
    GROUP BY 
        pv.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    u.DisplayName AS OwnerDisplayName,
    pu.PostCount,
    pv.UpVotes,
    pv.DownVotes,
    CASE 
        WHEN pv.UpVotes > 0 THEN 'Positive'
        WHEN pv.DownVotes > 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    TopUsers pu ON u.Id = pu.UserId
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.Score DESC, rp.CreationDate ASC
LIMIT 50;