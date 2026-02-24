WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, u.DisplayName
),
AggregateVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE  
        v.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days' 
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    av.UpVotes,
    av.DownVotes,
    CASE 
        WHEN av.UpVotes IS NULL THEN 0 
        ELSE av.UpVotes 
    END AS EffectiveUpVotes,
    CASE 
        WHEN av.DownVotes IS NULL THEN 0 
        ELSE av.DownVotes 
    END AS EffectiveDownVotes,
    CASE 
        WHEN rp.RankByScore <= 10 THEN 'Top'
        WHEN rp.RankByScore > 10 AND rp.RankByScore <= 50 THEN 'Mid'
        ELSE 'Low'
    END AS ScoreCategory
FROM 
    RankedPosts rp 
LEFT JOIN 
    AggregateVotes av ON rp.PostId = av.PostId
WHERE 
    rp.CommentCount > 5
ORDER BY 
    rp.CreationDate DESC
LIMIT 100;