
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COALESCE(u.DisplayName, 'Anonymous') AS UserDisplayName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
),
PostScoreSummary AS (
    SELECT 
        PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        PostId
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        ps.UpVotes,
        ps.DownVotes,
        rp.UserDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostScoreSummary ps ON rp.PostId = ps.PostId
    WHERE 
        rp.rn = 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.UserDisplayName,
    CASE 
        WHEN pd.UpVotes IS NULL OR pd.DownVotes IS NULL THEN 'Vote data unavailable'
        ELSE CASE 
            WHEN pd.UpVotes > pd.DownVotes THEN 'Positive'
            WHEN pd.UpVotes < pd.DownVotes THEN 'Negative'
            ELSE 'Neutral'
        END
    END AS VoteSentiment
FROM 
    PostDetails pd
WHERE 
    pd.ViewCount > (SELECT AVG(ViewCount) FROM Posts) 
    AND (pd.Score > 0 OR pd.UpVotes IS NOT NULL)
ORDER BY 
    pd.Score DESC, pd.ViewCount DESC
LIMIT 50;
