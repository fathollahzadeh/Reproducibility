WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank = 1
),
UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    u.DisplayName AS VoterDisplayName,
    u.UpVotes,
    u.DownVotes,
    CASE 
        WHEN u.UpVotes > u.DownVotes THEN 'Positive' 
        WHEN u.UpVotes < u.DownVotes THEN 'Negative' 
        ELSE 'Neutral' 
    END AS VoteSentiment
FROM 
    TopPosts tp
LEFT JOIN 
    UserVoteStats u ON tp.OwnerDisplayName = u.DisplayName
WHERE 
    tp.Score > (SELECT AVG(Score) FROM Posts WHERE PostTypeId = 1 AND Score IS NOT NULL)
ORDER BY 
    tp.Score DESC
LIMIT 10;