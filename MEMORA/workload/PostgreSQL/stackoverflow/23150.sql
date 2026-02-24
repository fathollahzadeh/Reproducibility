WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.AcceptedAnswerId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
AggregatedVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        COALESCE(ag.UpVotes, 0) AS UpVotes,
        COALESCE(ag.DownVotes, 0) AS DownVotes,
        rp.Rank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        AggregatedVotes ag ON rp.PostId = ag.PostId
    WHERE 
        rp.Rank <= 5
),
TopPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.ViewCount,
        pd.UpVotes,
        pd.DownVotes,
        pd.CreationDate,
        CASE 
            WHEN pd.UpVotes - pd.DownVotes > 0 THEN 'Positive'
            WHEN pd.UpVotes - pd.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS VoteSentiment,
        DENSE_RANK() OVER (ORDER BY pd.ViewCount DESC) AS ViewRank
    FROM 
        PostDetails pd
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.VoteSentiment,
    tp.ViewRank,
    ph.Comment AS LastCloseReason
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistory ph ON tp.PostId = ph.PostId AND ph.PostHistoryTypeId = 10
WHERE 
    tp.ViewRank <= 10
ORDER BY 
    tp.ViewRank, tp.Title;