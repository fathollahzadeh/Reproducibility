
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        unnest(string_to_array(p.Tags, '><')) AS tag ON true
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName, p.ViewCount, p.Score, p.CreationDate
),

RecentUserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE 
        v.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        v.UserId
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    rp.Tags,
    u.Reputation AS OwnerReputation,
    rv.VoteCount AS RecentVoteCount,
    rv.UpVotes AS RecentUpVotes,
    rv.DownVotes AS RecentDownVotes
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerDisplayName = u.DisplayName
LEFT JOIN 
    RecentUserVotes rv ON u.Id = rv.UserId
WHERE 
    rp.PostRank <= 3 
ORDER BY 
    rp.ViewCount DESC, rp.Score DESC;
