
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS ViewRank,
        COUNT(v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.Score >= 0 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, u.DisplayName, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        ViewRank <= 10
),
PostVoteStats AS (
    SELECT 
        PostId,
        SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    JOIN 
        VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.ViewCount,
        tp.Score,
        pvs.UpVotes,
        pvs.DownVotes,
        tp.CreationDate,
        tp.OwnerDisplayName
    FROM 
        TopPosts tp
    LEFT JOIN 
        PostVoteStats pvs ON tp.PostId = pvs.PostId
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.ViewCount,
    pd.Score,
    COALESCE(pd.UpVotes, 0) AS TotalUpVotes,
    COALESCE(pd.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN pd.Score > 0 THEN 'Positive'
        WHEN pd.Score < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS ScoreType
FROM 
    PostDetails pd
ORDER BY 
    pd.ViewCount DESC;
