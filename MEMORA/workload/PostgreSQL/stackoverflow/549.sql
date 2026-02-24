
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RowNum
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
HighScoringPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ur.Reputation,
        pv.UpVotes,
        pv.DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        UserReputation ur ON ur.PostCount > 10 AND ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
    LEFT JOIN 
        PostVotes pv ON pv.PostId = rp.PostId
    WHERE 
        rp.RowNum <= 5
)
SELECT 
    hsp.PostId,
    hsp.Title,
    hsp.CreationDate,
    hsp.Score,
    COALESCE(hsp.UpVotes, 0) AS UpVotes,
    COALESCE(hsp.DownVotes, 0) AS DownVotes,
    COALESCE(hsp.Reputation, 0) AS UserReputation
FROM 
    HighScoringPosts hsp
WHERE 
    hsp.Score > 0
ORDER BY 
    hsp.Score DESC, hsp.ViewCount DESC
FETCH FIRST 100 ROWS ONLY;
