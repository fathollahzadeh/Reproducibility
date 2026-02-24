WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        COALESCE(ph.UserDisplayName, 'Unknown') AS LastEditor,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Posts p ON rp.PostId = p.Id
    LEFT JOIN 
        PostHistory ph ON p.LastEditorUserId = ph.UserId 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        rp.ScoreRank <= 5
    GROUP BY 
        rp.PostId, rp.Title, rp.Score, ph.UserDisplayName
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.Score,
    pd.LastEditor,
    pd.CommentCount,
    pd.UpVoteCount,
    pd.DownVoteCount,
    (pd.UpVoteCount - pd.DownVoteCount) AS NetVotes,
    CASE 
        WHEN pd.Score > 10 THEN 'High'
        WHEN pd.Score BETWEEN 1 AND 10 THEN 'Medium'
        ELSE 'Low'
    END AS Popularity
FROM 
    PostDetails pd 
WHERE 
    pd.CommentCount > 0 
    AND pd.LastEditor IS NOT NULL 
ORDER BY 
    pd.Score DESC;