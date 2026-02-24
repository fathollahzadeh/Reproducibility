
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.ScoreRank <= 5
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.CreationDate,
        tp.OwnerDisplayName,
        COALESCE(pv.UpVotes, 0) AS UpVotes,
        COALESCE(pv.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN tp.Score >= 0 THEN 'Positive'
            WHEN tp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreCategory
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVotes pv ON tp.PostId = pv.PostId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.OwnerDisplayName,
    pd.UpVotes,
    pd.DownVotes,
    pd.ScoreCategory,
    'This post has ' || COALESCE(pd.UpVotes, 0) || ' upvotes and ' || COALESCE(pd.DownVotes, 0) || ' downvotes' AS VoteDescription
FROM 
    PostDetails pd
WHERE 
    pd.UpVotes > pd.DownVotes
ORDER BY 
    pd.CreationDate DESC
LIMIT 10;
