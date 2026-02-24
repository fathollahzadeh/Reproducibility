WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        rp.VoteCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.PostId = u.Id
    WHERE 
        rp.UserPostRank <= 5
),
RecentVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        v.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 month'
    GROUP BY 
        p.Id
)
SELECT 
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.VoteCount,
    fp.OwnerDisplayName,
    fp.OwnerReputation,
    rv.TotalVotes
FROM 
    FilteredPosts fp
LEFT JOIN 
    RecentVotes rv ON fp.PostId = rv.PostId
ORDER BY 
    fp.Score DESC, fp.ViewCount DESC;