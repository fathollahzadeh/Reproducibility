WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        OwnerDisplayName,
        Reputation
    FROM 
        RankedPosts
    WHERE 
        Rank <= 3
),
PostVoteCounts AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.Reputation,
    pvc.UpVotes,
    pvc.DownVotes,
    (tp.ViewCount + COALESCE(pvc.UpVotes, 0) - COALESCE(pvc.DownVotes, 0)) AS EngagementScore
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts pvc ON tp.PostId = pvc.PostId
ORDER BY 
    EngagementScore DESC;