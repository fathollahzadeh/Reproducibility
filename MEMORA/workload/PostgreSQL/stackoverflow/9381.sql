WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
RecentVotes AS (
    SELECT 
        v.PostId,
        COUNT(*) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.OwnerDisplayName,
        COALESCE(rv.VoteCount, 0) AS RecentVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        RecentVotes rv ON rp.PostId = rv.PostId
    WHERE 
        rp.PostRank <= 5
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.RecentVoteCount,
    pt.Name AS PostTypeName,
    COUNT(DISTINCT c.Id) AS CommentCount
FROM 
    PostDetails pd
JOIN 
    PostTypes pt ON pd.PostId IN (SELECT Id FROM Posts WHERE PostTypeId = pt.Id)
LEFT JOIN 
    Comments c ON pd.PostId = c.PostId
GROUP BY 
    pd.Title, pd.CreationDate, pd.Score, pd.ViewCount, pd.OwnerDisplayName, pd.RecentVoteCount, pt.Name
ORDER BY 
    pd.Score DESC, pd.RecentVoteCount DESC, pd.CreationDate DESC;