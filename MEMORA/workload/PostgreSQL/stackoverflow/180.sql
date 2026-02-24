WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COALESCE(u.Reputation, 0) AS UserReputation
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
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
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '6 months'
    GROUP BY 
        v.PostId
),
PostWithVotes AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.UserReputation,
        COALESCE(rv.VoteCount, 0) AS TotalVotes,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
)
SELECT 
    pwv.PostId,
    pwv.Title,
    pwv.Score,
    pwv.UserReputation,
    pwv.TotalVotes,
    pwv.UpVotes,
    pwv.DownVotes,
    CASE 
        WHEN pwv.Score >= 10 THEN 'High Score'
        WHEN pwv.Score BETWEEN 5 AND 9 THEN 'Medium Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    PostWithVotes pwv
WHERE 
    pwv.UserReputation > 50
ORDER BY 
    pwv.Score DESC NULLS LAST
FETCH FIRST 10 ROWS ONLY;