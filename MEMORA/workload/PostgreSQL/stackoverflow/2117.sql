
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Score,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        (SELECT COUNT(*) 
         FROM Comments c 
         WHERE c.PostId = p.Id AND c.Score > 0) AS PositiveCommentCount,
        CASE 
            WHEN p.LastActivityDate IS NULL THEN 'No Activity' 
            WHEN p.LastActivityDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days' THEN 'Inactive' 
            ELSE 'Active' 
        END AS ActivityStatus
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATE '2024-10-01' - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        pv.UpVotes,
        pv.DownVotes,
        rp.ActivityStatus,
        rp.PositiveCommentCount,
        rp.ScoreRank
    FROM 
        RankedPosts rp
    LEFT JOIN 
        PostVotes pv ON rp.PostID = pv.PostId
)
SELECT 
    pd.Title,
    pd.Score,
    pd.ViewCount,
    pd.UpVotes,
    pd.DownVotes,
    pd.ActivityStatus,
    CASE 
        WHEN pd.PositiveCommentCount IS NULL THEN 'No Comments'
        WHEN pd.PositiveCommentCount = 0 THEN 'No Positive Comments'
        ELSE CONCAT('Positive Comments: ', pd.PositiveCommentCount)
    END AS CommentInfo
FROM 
    PostDetails pd
WHERE 
    pd.ScoreRank <= 5
ORDER BY 
    pd.Score DESC
LIMIT 10;
