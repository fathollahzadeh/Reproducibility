WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        (SELECT COUNT(DISTINCT c.Id) 
         FROM Comments c 
         WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) 
         FROM Votes v 
         WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)) AS VoteCount
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (cast('2024-10-01' as date) - INTERVAL '1 year')
),
UserVotes AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId IN (2, 3) THEN 1 ELSE 0 END) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    WHERE 
        u.Reputation > 500
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, ph.UserId, ph.CreationDate, ph.Comment
)
SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation,
    rp.CreationDate AS PostCreationDate,
    rp.CommentCount,
    rp.VoteCount,
    uv.UpVotes,
    uv.DownVotes,
    COALESCE(hd.HistoryTypes, 'No history') AS PostHistory,
    CASE 
        WHEN u.Location IS NULL OR u.Location = '' THEN 'Location unspecified'
        ELSE u.Location 
    END AS UserLocation
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
LEFT JOIN 
    PostHistoryDetails hd ON rp.PostId = hd.PostId
WHERE 
    rp.PostRank = 1 
AND 
    (rp.CommentCount > 2 OR uv.TotalVotes > 5)
ORDER BY 
    u.Reputation DESC, rp.VoteCount DESC
LIMIT 50;