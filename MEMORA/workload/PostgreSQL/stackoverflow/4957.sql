
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate
),
TopPosts AS (
    SELECT 
        rp.PostId, rp.Title, rp.Score, rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank = 1
),
PostVoteInfo AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        (COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) - 
         COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0)) AS NetVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    pvi.UpVotes,
    pvi.DownVotes,
    pvi.NetVotes,
    CASE 
        WHEN tp.CommentCount > 100 THEN 'Highly Discussed'
        WHEN tp.CommentCount BETWEEN 50 AND 100 THEN 'Moderately Discussed'
        ELSE 'Less Discussed'
    END AS DiscussionLevel,
    CASE 
        WHEN pvi.NetVotes > 0 THEN 'Positive'
        WHEN pvi.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM 
    TopPosts tp
JOIN 
    PostVoteInfo pvi ON tp.PostId = pvi.PostId
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 months' AND TIMESTAMP '2024-10-01 12:34:56'
    AND ph.PostHistoryTypeId IN (10, 11, 12)  
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
