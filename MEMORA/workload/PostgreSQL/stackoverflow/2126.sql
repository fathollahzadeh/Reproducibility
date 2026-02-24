WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
    AND 
        p.Score > 0
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(*) FILTER (WHERE VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE VoteTypeId = 3) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),
PostComments AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.Score,
    pv.UpVotes,
    pv.DownVotes,
    pc.CommentCount,
    CASE 
        WHEN pv.UpVotes IS NOT NULL AND pv.DownVotes IS NOT NULL 
        THEN (pv.UpVotes - pv.DownVotes) 
        ELSE NULL 
    END AS NetVotes,
    CASE 
        WHEN rp.Rank <= 10 THEN 'Top 10' 
        ELSE 'Other' 
    END AS RankingCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteCounts pv ON rp.PostId = pv.PostId
LEFT JOIN 
    PostComments pc ON rp.PostId = pc.PostId
WHERE 
    rp.Rank <= 20
ORDER BY 
    rp.Rank;